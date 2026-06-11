import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timbangan_spd/app/module/Login/controller/login_controller.dart';

// ─────────────────────────────────────────────
// Auto Logout Wrapper
// ─────────────────────────────────────────────
class AutoLogoutWrapper extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;
  final Duration checkInterval;

  const AutoLogoutWrapper({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 60), // ✅ 1 jam
    this.checkInterval = const Duration(seconds: 60),
  });

  @override
  State<AutoLogoutWrapper> createState() => _AutoLogoutWrapperState();
}

class _AutoLogoutWrapperState extends State<AutoLogoutWrapper> {
  DateTime _lastInteraction = DateTime.now();
  bool _isShowingDialog = false;
  Timer? _timer; // ✅ pakai Timer agar bisa di-cancel

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ cancel timer saat widget dispose
    super.dispose();
  }

  // ✅ Cancel timer lama dulu, baru buat yang baru
  // Ini mencegah multiple timer berjalan bersamaan
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.checkInterval, (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      if (!_isShowingDialog) _checkInactivity();
    });
  }

  void _checkInactivity() {
    final elapsed = DateTime.now().difference(_lastInteraction);
    if (elapsed >= widget.timeoutDuration) {
      _timer?.cancel(); // ✅ stop timer sebelum tampilkan dialog
      _performAutoLogout();
    }
  }

  Future<void> _performAutoLogout() async {
    if (!mounted || _isShowingDialog) return;
    _isShowingDialog = true;

    final shouldLogout = await _showDialog();
    _isShowingDialog = false;

    if (!mounted) return;

    if (shouldLogout) {
      await Get.find<LoginController>().logout();
      if (mounted) {
        Get.snackbar(
          'Sesi Berakhir',
          'Sesi berakhir karena tidak aktif.',
          backgroundColor: const Color(0xFFF59E0B),
          colorText: Colors.white,
          borderRadius: 10,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      // ✅ User klik Lanjutkan — reset waktu & restart timer sekali
      _lastInteraction = DateTime.now();
      _startTimer(); // hanya dipanggil sekali di sini
    }
  }

  Future<bool> _showDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(children: [
          Icon(Icons.timer_off_rounded, color: Color(0xFFF59E0B), size: 26),
          SizedBox(width: 10),
          Text('Sesi Akan Berakhir',
              style: TextStyle(color: Color(0xFF1E2A4A), fontSize: 16)),
        ]),
        content: Text(
          'Anda tidak aktif selama ${widget.timeoutDuration.inMinutes} menit.\n'
          'Apakah ingin melanjutkan sesi?',
          style: const TextStyle(color: Color(0xFF3D4E7A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Logout',
                style: TextStyle(color: Color(0xFFEF5350))),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C8EF5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? true;
  }

  void _onInteraction() => _lastInteraction = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _onInteraction(),
      onEnter: (_) => _onInteraction(),
      child: widget.child,
    );
  }
}
