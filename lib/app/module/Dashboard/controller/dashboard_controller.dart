import 'dart:async';
import 'dart:html' as html;
import 'package:get/get.dart';
import 'package:timbangan_spd/app/models/scale_model.dart';

class DashboardController extends GetxController {
  // ── Observables ──────────────────────────────────────────────────────────
  final scales = <ScaleDevice>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  // ── Computed ──────────────────────────────────────────────────────────────
  int get onlineCount =>
      scales.where((s) => s.status == ScaleStatus.online).length;
  int get offlineCount =>
      scales.where((s) => s.status == ScaleStatus.offline).length;
  int get warningCount =>
      scales.where((s) => s.status == ScaleStatus.warning).length;

  // ── Disabled scales (hardcode offline, tidak di-ping) ─────────────────────
  static const _disabledIds = {1, 2}; // hanya L1, L2

  // ── Timers ────────────────────────────────────────────────────────────────
  Timer? _periodicTimer;
  final Map<int, Timer> _offlineTimeouts = {};

  // ── Sample Scales ─────────────────────────────────────────────────────────
  static final _sampleScales = [
    const ScaleDevice(
        id: 1,
        name: 'Timbangan  L1',
        location: 'Area ',
        ip: '192.168.x.x',
        unit: 'kg',
        description: 'Timbangan unit 1'),
    const ScaleDevice(
        id: 2,
        name: 'Timbangan  L2',
        location: 'Area ',
        ip: '192.168.x.x',
        unit: 'kg',
        description: 'Timbangan unit 2'),
    const ScaleDevice(
        id: 4,
        name: 'Timbangan  L4',
        location: 'Area ',
        ip: '192.168.x.x',
        unit: 'kg',
        description: 'Timbangan unit 4'),
    const ScaleDevice(
        id: 5,
        name: 'Timbangan  L5',
        location: 'Area ',
        ip: '192.168.x.x',
        unit: 'kg',
        description: 'Timbangan unit 5'),
    const ScaleDevice(
        id: 6,
        name: 'Timbangan  L6',
        location: 'Area ',
        ip: '192.168.x.x',
        unit: 'kg',
        description: 'Timbangan unit 6'),
    const ScaleDevice(
        id: 7,
        name: 'Timbangan  L7',
        location: 'Area ',
        ip: '192.168.x.x',
        unit: 'kg',
        description: 'Timbangan unit 7'),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    loadScales();
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    for (final t in _offlineTimeouts.values) t.cancel();
    super.onClose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> loadScales() async {
    isLoading.value = true;
    errorMessage.value = null;
    await Future.delayed(const Duration(milliseconds: 600));

    scales.value = _sampleScales
        .map((s) => s.copyWith(status: ScaleStatus.loading))
        .toList();

    isLoading.value = false;
    _startOfflineTimeouts();
    _startPeriodicCheck();

    for (int i = 0; i < scales.length; i++) {
      checkDeviceStatus(i);
    }
  }

  // ── Offline timeout jika tidak ada respons ────────────────────────────────
  void _startOfflineTimeouts({int timeoutSeconds = 8}) {
    for (int i = 0; i < scales.length; i++) {
      _scheduleOfflineTimeout(i, timeoutSeconds: timeoutSeconds);
    }
  }

  void _scheduleOfflineTimeout(int index, {int timeoutSeconds = 8}) {
    _offlineTimeouts[index]?.cancel();
    _offlineTimeouts[index] = Timer(
      Duration(seconds: timeoutSeconds),
      () {
        if (index < scales.length &&
            scales[index].status == ScaleStatus.loading) {
          _updateScale(index, ScaleStatus.offline);
        }
      },
    );
  }

  // ── Periodic check setiap 30 detik (lebih cepat dari 2 menit) ─────────────
  void _startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Hanya set loading untuk yang bukan disabled
      final updated = scales.map((s) {
        if (_disabledIds.contains(s.id)) return s; // skip disabled
        return s.copyWith(status: ScaleStatus.loading);
      }).toList();
      scales.value = updated;

      _startOfflineTimeouts();

      for (int i = 0; i < scales.length; i++) {
        checkDeviceStatus(i);
      }
    });
  }

  // ── Refresh ───────────────────────────────────────────────────────────────
  Future<void> refreshDevices() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 400));

    final updated = scales.map((s) {
      if (_disabledIds.contains(s.id)) return s;
      return s.copyWith(status: ScaleStatus.loading);
    }).toList();
    scales.value = updated;

    isLoading.value = false;
    _startOfflineTimeouts();
    for (int i = 0; i < scales.length; i++) {
      checkDeviceStatus(i);
    }
  }

  // ── Update status ─────────────────────────────────────────────────────────
  void updateScaleStatus(int index, ScaleStatus status) {
    if (index >= scales.length) return;
    if (status == ScaleStatus.online) {
      _offlineTimeouts[index]?.cancel();
    }
    _updateScale(index, status);
  }

  void _updateScale(int index, ScaleStatus status) {
    if (index >= scales.length) return;
    final updated = List<ScaleDevice>.from(scales);
    updated[index] = updated[index].copyWith(
      status: status,
      lastUpdate: DateTime.now(),
    );
    scales.value = updated;
  }

  // ── Image ping untuk cek status device ───────────────────────────────────
  void checkDeviceStatus(int index) {
    if (index >= scales.length) return;

    // Disabled → langsung offline, tidak di-ping
    if (_disabledIds.contains(scales[index].id)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        updateScaleStatus(index, ScaleStatus.offline);
      });
      return;
    }

    final ip = scales[index].ip;
    final isValidIp = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(ip);

    if (!isValidIp) {
      Future.delayed(const Duration(milliseconds: 300), () {
        updateScaleStatus(index, ScaleStatus.offline);
      });
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final img = html.ImageElement();
    Timer? timeoutTimer;

    // Timeout 5 detik → offline
    timeoutTimer = Timer(const Duration(seconds: 5), () {
      img.src = '';
      updateScaleStatus(index, ScaleStatus.offline);
    });

    img.onLoad.listen((_) {
      timeoutTimer?.cancel();
      updateScaleStatus(index, ScaleStatus.online);
    });

    img.onError.listen((_) {
      timeoutTimer?.cancel();
      // Error dari browser = device ada tapi gambar tidak ada = ONLINE
      updateScaleStatus(index, ScaleStatus.online);
    });

    img.src = 'http://$ip/favicon.ico?_=$timestamp';
  }
}