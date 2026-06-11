import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timbangan_spd/app/core/utils/app_constants.dart';
import 'package:timbangan_spd/app/models/analytics_model.dart';
import 'package:timbangan_spd/app/models/weight_record_model.dart';
import 'package:timbangan_spd/app/service/api_service.dart';

class AnalyticsController extends GetxController {
  // ── Observables ──────────────────────────────────────────────────────────
  final dailyData        = <DailyProduction>[].obs;
  final linePerformance  = <LinePerformance>[].obs;
  final isLoading        = false.obs;
  final errorMessage     = RxnString();
  final records          = <WeightRecord>[].obs;
  final isRefreshing     = false.obs;
  final hasSearched      = false.obs;
  final lastUpdated      = Rxn<DateTime>();

  /// 0 = Record A, 1 = Record B
  final chartTab = 0.obs;

  /// Filter source: 'Semua', 'Manual', 'Auto'
  final selectedSource = 'Semua'.obs;
  static const sources = ['Semua', 'Manual', 'Auto'];

  // ── Filter tanggal — DEFAULT: hari ini ────────────────────────────────────
  final startDate = Rx<DateTime?>(DateTime.now());
  final endDate   = Rx<DateTime?>(DateTime.now());

  // ── Records (sudah difilter via API) ──────────────────────────────────────
  List<WeightRecord> get filteredRecords => records.toList();

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER: group records per key (line_shift atau line_shift_date)
  // Ambil baris TERAKHIR per group → untuk Total Rec
  // ═══════════════════════════════════════════════════════════════════════════

  /// Group records per line+shift, ambil last record per group.
  /// Returns list of last WeightRecord per line+shift.
  static List<WeightRecord> _lastPerLineShift(List<WeightRecord> recs) {
    final Map<String, List<WeightRecord>> grouped = {};
    for (final r in recs) {
      final key = '${r.line ?? "?"}_${r.shift ?? "-"}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(r);
    }
    return grouped.values.map((list) {
      list.sort((a, b) => b.dbTime.compareTo(a.dbTime));
      return list.first;
    }).toList();
  }

  /// Group records per line+shift+date, ambil last record per group.
  /// Returns list of last WeightRecord per line+shift+date.
  static List<WeightRecord> _lastPerLineShiftDate(List<WeightRecord> recs) {
    final Map<String, List<WeightRecord>> grouped = {};
    for (final r in recs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(r.dbTime);
      final key = '${r.line ?? "?"}_${r.shift ?? "-"}_$dateKey';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(r);
    }
    return grouped.values.map((list) {
      list.sort((a, b) => b.dbTime.compareTo(a.dbTime));
      return list.first;
    }).toList();
  }

  // ── Computed — Total Production pakai last record per line+shift ──────────
  // totalProduction = SUM recordHistoryAll dari baris TERAKHIR per line+shift
  double get totalProduction {
    final lastRecs = _lastPerLineShift(filteredRecords);
    return lastRecs.fold(0.0, (s, r) => s + r.recordHistoryAll);
  }

  double get avgDailyProduction =>
      dailyData.isEmpty ? 0.0 : totalProduction / dailyData.length;

  double get maxDailyProduction => dailyData.isEmpty
      ? 0.0
      : dailyData.map((d) => d.totalWeight).reduce((a, b) => a > b ? a : b);

  int get totalTransactions => filteredRecords.length;

  // totalRecordA & B = SUM semua (bukan last) — ini memang SUM keseluruhan
  double get totalRecordA =>
      filteredRecords.fold(0.0, (s, r) => s + r.recordWeightA);
  double get totalRecordB =>
      filteredRecords.fold(0.0, (s, r) => s + r.recordWeightB);

  // ── Real Weight Computed — SUM semua (benar) ──────────────────────────────
  double get totalRealWeightA =>
      filteredRecords.fold(0.0, (s, r) => s + r.realWeightA);
  double get totalRealWeightB =>
      filteredRecords.fold(0.0, (s, r) => s + r.realWeightB);
  double get totalRealWeight =>
      filteredRecords.fold(0.0, (s, r) => s + r.totalRealWeight);

  Map<String, double> get perLineRecordA {
    final map = <String, double>{};
    for (final r in filteredRecords) {
      final l = r.line ?? 'Unknown';
      map[l] = (map[l] ?? 0.0) + r.recordWeightA;
    }
    return map;
  }

  Map<String, double> get perLineRecordB {
    final map = <String, double>{};
    for (final r in filteredRecords) {
      final l = r.line ?? 'Unknown';
      map[l] = (map[l] ?? 0.0) + r.recordWeightB;
    }
    return map;
  }

  List<DailyProduction> get dailyDataA => _buildDailyByField(useA: true);
  List<DailyProduction> get dailyDataB => _buildDailyByField(useA: false);

  List<DailyProduction> _buildDailyByField({required bool useA}) {
    final src = filteredRecords;
    if (src.isEmpty) return [];
    final Map<String, Map<String, dynamic>> dayMap = {};
    for (final r in src) {
      final dayKey = DateFormat('yyyy-MM-dd').format(r.dbTime);
      dayMap.putIfAbsent(
        dayKey,
        () => {
          'date'        : DateTime(r.dbTime.year, r.dbTime.month, r.dbTime.day),
          'totalWeight' : 0.0,
          'transactions': 0,
          'perLine'     : <String, double>{},
        },
      );
      final weight = useA ? r.recordWeightA : r.recordWeightB;
      dayMap[dayKey]!['totalWeight'] =
          (dayMap[dayKey]!['totalWeight'] as double) + weight;
      dayMap[dayKey]!['transactions'] =
          (dayMap[dayKey]!['transactions'] as int) + 1;
      final line   = r.line ?? 'Unknown';
      final perLine = dayMap[dayKey]!['perLine'] as Map<String, double>;
      perLine[line] = (perLine[line] ?? 0.0) + weight;
    }
    final sortedDays = dayMap.values.toList()
      ..sort((a, b) =>
          (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return sortedDays
        .map((d) => DailyProduction(
              date        : d['date']         as DateTime,
              totalWeight : d['totalWeight']  as double,
              transactions: d['transactions'] as int,
              perLine     : Map<String, double>.from(d['perLine'] as Map),
            ))
        .toList();
  }

  Timer? _refreshTimer;

  final filter = HistoryFilter(
    startDate: DateTime.now(),
    endDate  : DateTime.now(),
    source   : null,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
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
    isRefreshing.value  = true;
    errorMessage.value  = null;
    final result = await ApiService.getWeightHistory(filter.value);
    records.value = result;
    _buildAnalytics(result);
    isRefreshing.value  = false;
    hasSearched.value   = true;
    lastUpdated.value   = DateTime.now();
    errorMessage.value  =
        result.isEmpty ? 'Tidak ada data untuk filter ini.' : null;
  }

  void setStartDate(DateTime? d) => startDate.value = d;
  void setEndDate(DateTime? d)   => endDate.value   = d;

  void setSource(String source) {
    selectedSource.value = source;
    if (source == 'Semua') {
      filter.value = filter.value.copyWith(clearSource: true);
    } else {
      filter.value = filter.value.copyWith(source: source);
    }
    _buildAnalytics(records.toList());
  }

  Future<void> search() async {
    if (startDate.value == null || endDate.value == null) return;
    await loadData();
  }

  Future<void> loadData() async {
    isLoading.value    = true;
    errorMessage.value = null;

    final start         = startDate.value ?? DateTime.now();
    final end           = endDate.value   ?? DateTime.now();
    final currentSource = selectedSource.value;

    filter.value = HistoryFilter(
      startDate: start,
      endDate  : end,
      source   : currentSource == 'Semua' ? null : currentSource,
    );

    final fetchedRecords = await ApiService.getWeightHistory(filter.value);
    records.value = fetchedRecords;

    if (fetchedRecords.isEmpty) {
      dailyData.value       = [];
      linePerformance.value = [];
      isLoading.value       = false;
      hasSearched.value     = true;
      errorMessage.value    = 'Tidak ada data untuk filter ini.';
      _startAutoRefresh();
      return;
    }

    _buildAnalytics(fetchedRecords);
    isLoading.value   = false;
    lastUpdated.value = DateTime.now();
    hasSearched.value = true;
    _startAutoRefresh();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD ANALYTICS
  // ── Daily Production: pakai last record per line+shift PER HARI
  //    → Total Rec per hari = SUM lastRecord.recordHistoryAll per line+shift
  // ── Line Performance : pakai last record per line+shift (tanpa tanggal)
  //    → Total Rec per line = SUM lastRecord.recordHistoryAll per shift
  // ═══════════════════════════════════════════════════════════════════════════
  void _buildAnalytics(List<WeightRecord> allRecords) {
    final useRecords = selectedSource.value == 'Semua'
        ? allRecords
        : allRecords.where((r) => r.source == selectedSource.value).toList();

    if (useRecords.isEmpty) {
      dailyData.value       = [];
      linePerformance.value = [];
      if (hasSearched.value) {
        errorMessage.value = 'Tidak ada data untuk filter ini.';
      }
      return;
    }

    errorMessage.value = null;

    // ── Daily Production ──────────────────────────────────────────────────
    // Ambil last record per line+shift+date → group by date → SUM recordHistoryAll
    final lastPerDay = _lastPerLineShiftDate(useRecords);

    final Map<String, Map<String, dynamic>> dayMap = {};
    for (final r in lastPerDay) {
      final dayKey = DateFormat('yyyy-MM-dd').format(r.dbTime);
      dayMap.putIfAbsent(
        dayKey,
        () => {
          'date'        : DateTime(r.dbTime.year, r.dbTime.month, r.dbTime.day),
          'totalWeight' : 0.0,
          'transactions': 0,
          'perLine'     : <String, double>{},
        },
      );
      // Total Rec = recordHistoryAll dari last record per line+shift per hari
      final weight  = r.recordHistoryAll;
      dayMap[dayKey]!['totalWeight'] =
          (dayMap[dayKey]!['totalWeight'] as double) + weight;
      dayMap[dayKey]!['transactions'] =
          (dayMap[dayKey]!['transactions'] as int) + 1;

      final line    = r.line ?? 'Unknown';
      final perLine = dayMap[dayKey]!['perLine'] as Map<String, double>;
      perLine[line] = (perLine[line] ?? 0.0) + weight;
    }

    final sortedDays = dayMap.values.toList()
      ..sort((a, b) =>
          (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    dailyData.value = sortedDays
        .map((d) => DailyProduction(
              date        : d['date']         as DateTime,
              totalWeight : d['totalWeight']  as double,
              transactions: d['transactions'] as int,
              perLine     : Map<String, double>.from(d['perLine'] as Map),
            ))
        .toList();

    // ── Line Performance ──────────────────────────────────────────────────
    // Ambil last record per line+shift (tanpa tanggal) → SUM per line
    final lastPerLineShift = _lastPerLineShift(useRecords);

    final Map<String, Map<String, dynamic>> lineMap = {};
    for (final r in lastPerLineShift) {
      final line = r.line ?? 'Unknown';
      lineMap.putIfAbsent(
        line,
        () => {
          'totalWeight'   : 0.0,
          'transactions'  : 0,
          'positiveWeight': 0.0,
          'negativeWeight': 0.0,
        },
      );
      // Total Rec per line = SUM recordHistoryAll dari last record per shift
      final weight = r.recordHistoryAll;
      lineMap[line]!['totalWeight'] =
          (lineMap[line]!['totalWeight'] as double) + weight;
      // transactions = jumlah shift yang ada di line ini
      lineMap[line]!['transactions'] =
          (lineMap[line]!['transactions'] as int) + 1;
      if (weight >= 0) {
        lineMap[line]!['positiveWeight'] =
            (lineMap[line]!['positiveWeight'] as double) + weight;
      } else {
        lineMap[line]!['negativeWeight'] =
            (lineMap[line]!['negativeWeight'] as double) + weight.abs();
      }
    }

    linePerformance.value = lineMap.entries.map((e) {
      final tx    = e.value['transactions']   as int;
      final total = e.value['totalWeight']    as double;
      return LinePerformance(
        line           : e.key,
        totalWeight    : total,
        totalTransactions: tx,
        avgWeight      : tx > 0 ? total / tx : 0.0,
        positiveWeight : e.value['positiveWeight'] as double,
        negativeWeight : e.value['negativeWeight'] as double,
      );
    }).toList()
      ..sort((a, b) => b.totalWeight.compareTo(a.totalWeight));
  }
}