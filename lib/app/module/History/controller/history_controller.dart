import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timbangan_spd/app/core/utils/app_constants.dart';
import 'package:timbangan_spd/app/models/weight_record_model.dart';
import 'package:timbangan_spd/app/service/api_service.dart';
import 'package:timbangan_spd/app/service/excel_export_service.dart';

class HistoryController extends GetxController {
  // ── Observables ──────────────────────────────────────────────────────────
  final records      = <WeightRecord>[].obs;
  final isLoading    = false.obs;
  final isRefreshing = false.obs;
  final isExporting  = false.obs;
  final hasSearched  = false.obs;
  final errorMessage = RxnString();
  final lastUpdated  = Rxn<DateTime>();

  final selectedSource = 'Semua'.obs;
  static const sources = ['Semua', 'Manual', 'Auto'];

  final startDate = Rx<DateTime?>(DateTime.now());
  final endDate   = Rx<DateTime?>(DateTime.now());

  final filter = HistoryFilter(
    startDate: DateTime.now(),
    endDate: DateTime.now(),
    source: null,
  ).obs;

  List<WeightRecord> get filteredRecords => records.toList();

  double get totalWeight =>
      filteredRecords.fold(0.0, (s, r) => s + r.totalRealWeight);
  int get totalRecords => filteredRecords.length;

  double get totalRealWeightA =>
      filteredRecords.fold(0.0, (s, r) => s + r.realWeightA);
  double get totalRealWeightB =>
      filteredRecords.fold(0.0, (s, r) => s + r.realWeightB);
  double get totalRealWeightAll =>
      filteredRecords.fold(0.0, (s, r) => s + r.totalRealWeight);

  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    filter.value = HistoryFilter(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      source: null,
    );
    fetchHistory();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: AppConstants.historyRefreshSeconds),
      (_) => _silentRefresh(),
    );
  }

  Future<void> _silentRefresh() async {
    if (isLoading.value) return;
    isRefreshing.value = true;
    errorMessage.value = null;
    final result = await ApiService.getWeightHistory(filter.value);
    records.value = result;
    isRefreshing.value = false;
    hasSearched.value = true;
    lastUpdated.value = DateTime.now();
    errorMessage.value =
        result.isEmpty ? 'Tidak ada data untuk filter ini.' : null;
  }

  void setStartDate(DateTime? d) => startDate.value = d;
  void setEndDate(DateTime? d)   => endDate.value = d;

  void setLine(String? line) => filter.value = line == null
      ? filter.value.copyWith(clearLine: true)
      : filter.value.copyWith(line: line);

  void setShift(String? shift) => filter.value = shift == null
      ? filter.value.copyWith(clearShift: true)
      : filter.value.copyWith(shift: shift);

  void setSource(String source) {
    selectedSource.value = source;
    if (source == 'Semua') {
      filter.value = filter.value.copyWith(clearSource: true);
    } else {
      filter.value = filter.value.copyWith(source: source);
    }
  }

  void resetFilter() {
    final now = DateTime.now();
    startDate.value = now;
    endDate.value   = now;
    selectedSource.value = 'Semua';
    filter.value = HistoryFilter(
      startDate: now,
      endDate: now,
      source: null,
    );
    records.value = [];
    hasSearched.value = false;
    errorMessage.value = null;
    fetchHistory();
  }

  Future<void> search() async {
    if (startDate.value == null || endDate.value == null) return;
    await fetchHistory();
  }

  Future<void> fetchHistory() async {
    isLoading.value    = true;
    errorMessage.value = null;

    final start         = startDate.value ?? DateTime.now();
    final end           = endDate.value   ?? DateTime.now();
    final currentSource = selectedSource.value;

    filter.value = HistoryFilter(
      startDate: start,
      endDate: end,
      line: filter.value.line,
      shift: filter.value.shift,
      source: currentSource == 'Semua' ? null : currentSource,
    );

    final result = await ApiService.getWeightHistory(filter.value);
    records.value      = result;
    isLoading.value    = false;
    hasSearched.value  = true;
    lastUpdated.value  = DateTime.now();
    errorMessage.value =
        result.isEmpty ? 'Tidak ada data untuk filter ini.' : null;
  }

  // ── Export Excel (semua data / filter aktif) ──────────────────────────────
  Future<void> exportExcel() async {
    if (isExporting.value) return;

    if (filteredRecords.isEmpty) {
      Get.snackbar(
        'Tidak Ada Data',
        'Tidak ada data untuk diekspor. Tampilkan data terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEF3C7),
        colorText: const Color(0xFF92400E),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFF59E0B)),
      );
      return;
    }

    isExporting.value = true;
    try {
      await ExcelExportService.exportHistory(
        records:   filteredRecords,
        startDate: startDate.value,
        endDate:   endDate.value,
        line:      filter.value.line,
        shift:     filter.value.shift,
        source:    selectedSource.value,
      );
    } catch (e) {
      Get.snackbar(
        'Export Gagal',
        'Terjadi kesalahan saat membuat file Excel: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFF991B1B),
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error_outline_rounded,
            color: Color(0xFFEF4444)),
      );
    } finally {
      isExporting.value = false;
    }
  }

  // ── Export Excel khusus Shift 3 (22:00 startDate – 06:00 endDate) ─────────
  Future<void> exportExcelShift3Only() async {
    if (isExporting.value) return;

    final start = startDate.value;
    final end   = endDate.value;

    // Validasi: butuh kedua tanggal
    if (start == null || end == null) {
      Get.snackbar(
        'Filter Tidak Lengkap',
        'Tentukan tanggal mulai dan akhir terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEF3C7),
        colorText: const Color(0xFF92400E),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFF59E0B)),
      );
      return;
    }

    if (filteredRecords.isEmpty) {
      Get.snackbar(
        'Tidak Ada Data',
        'Tidak ada data untuk diekspor. Tampilkan data terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEF3C7),
        colorText: const Color(0xFF92400E),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFF59E0B)),
      );
      return;
    }

    isExporting.value = true;
    try {
      await ExcelExportService.exportHistoryShift3Only(
        records:   filteredRecords,
        startDate: start,
        endDate:   end,
        line:      filter.value.line,
        source:    selectedSource.value,
      );
    } catch (e) {
      Get.snackbar(
        'Export Gagal',
        'Terjadi kesalahan saat membuat file Excel: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFF991B1B),
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error_outline_rounded,
            color: Color(0xFFEF4444)),
      );
    } finally {
      isExporting.value = false;
    }
  }
}