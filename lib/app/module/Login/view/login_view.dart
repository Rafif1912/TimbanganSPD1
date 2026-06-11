import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timbangan_spd/app/module/Login/controller/login_controller.dart';

// ─────────────────────────────────────────────
// Login View
// ─────────────────────────────────────────────
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: isMobile ? _buildMobile(context) : _buildDesktop(context, w < 1100),
    );
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────────
  Widget _buildMobile(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        // Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 56, 28, 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4F6EF7), Color(0xFF7B52F5)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.scale, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            const Text('SPD Timbangan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Sistem Monitoring Timbangan Industri',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13)),
          ]),
        ),

        // Form card
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6C8EF5).withOpacity(0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 10)),
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Selamat Datang',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E2A4A))),
            const SizedBox(height: 4),
            Text('Masuk untuk mengakses sistem',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 28),
            const _LoginForm(),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text('PT. Pulau Sambu  •  SPD Division  •  2026',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.3)),
        ),
      ]),
    );
  }

  // ── Desktop Layout ─────────────────────────────────────────────────────────
  Widget _buildDesktop(BuildContext context, bool isTablet) {
    return Row(children: [
      if (!isTablet)
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4F6EF7), Color(0xFF7B52F5)],
              ),
            ),
            child: Stack(children: [
              Positioned(
                  top: -80,
                  left: -60,
                  child: _Circle(size: 280, opacity: 0.12)),
              Positioned(
                  bottom: -100,
                  right: -80,
                  child: _Circle(size: 360, opacity: 0.10)),
              Positioned(
                  top: 180,
                  right: -30,
                  child: _Circle(size: 160, opacity: 0.08)),
              Padding(
                padding: const EdgeInsets.all(52),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.scale,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 20),
                      const Text('SPD\nTimbangan',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 14),
                      Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 18),
                      Text('Sistem Monitoring Timbangan\nIndustri Terpadu',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 15,
                              height: 1.6)),
                      const Spacer(),
                      ...[
                        (
                          'Monitoring realtime seluruh unit',
                          Icons.speed_rounded
                        ),
                        (
                          'Analitik produksi harian & bulanan',
                          Icons.bar_chart_rounded
                        ),
                        ('Keamanan auto-logout sesi', Icons.security_rounded),
                        (
                          'Laporan performa timbangan',
                          Icons.assessment_rounded
                        ),
                      ].map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child:
                                    Icon(e.$2, color: Colors.white, size: 17),
                              ),
                              const SizedBox(width: 12),
                              Text(e.$1,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13)),
                            ]),
                          )),
                      const SizedBox(height: 28),
                      Text('PT. Pulau Sambu  •  SPD Division  •  2026',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11)),
                    ]),
              ),
            ]),
          ),
        ),

      // Form panel kanan
      Expanded(
        flex: isTablet ? 1 : 4,
        child: Container(
          color: const Color(0xFFF8F9FF),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 56, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 13, color: Color(0xFF6C8EF5)),
                              SizedBox(width: 6),
                              Text('Portal Masuk',
                                  style: TextStyle(
                                      color: Color(0xFF6C8EF5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      const Text('Selamat Datang',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E2A4A),
                              letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Masukkan kredensial untuk mengakses sistem.',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              height: 1.5)),
                      const SizedBox(height: 36),
                      const _LoginForm(),
                    ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
// Login Form
// ─────────────────────────────────────────────
class _LoginForm extends GetView<LoginController> {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Error banner
        Obx(() => controller.errorMessage.value != null
            ? _ErrorBanner(
                message: controller.errorMessage.value!,
                onDismiss: controller.clearError,
              )
            : const SizedBox.shrink()),

        _Label('Username'),
        const SizedBox(height: 8),
        _Field(
          ctrl: controller.usernameCtrl,
          hint: 'Masukkan username',
          icon: Icons.person_outline_rounded,
          onChanged: (_) => controller.onFieldChanged(),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Username wajib diisi' : null,
        ),
        const SizedBox(height: 20),
        _Label('Password'),
        const SizedBox(height: 8),
        Obx(() => _Field(
              ctrl: controller.passwordCtrl,
              hint: 'Masukkan password',
              icon: Icons.lock_outline_rounded,
              obscureText: !controller.showPassword.value,
              onChanged: (_) => controller.onFieldChanged(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.showPassword.value
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: const Color(0xFF6C8EF5),
                  size: 20,
                ),
                onPressed: controller.togglePassword,
              ),
            )),
        const SizedBox(height: 28),

        // Submit button
        Obx(() => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B6EE8),
                  disabledBackgroundColor: const Color(0xFFB8C5F8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Masuk ke Sistem',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            )),

        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: Divider(color: Colors.grey.shade200)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Butuh bantuan?',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ]),
        const SizedBox(height: 12),
        Center(
          child: Text('Hubungi administrator sistem Anda',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Color(0xFF1E2A4A), fontSize: 13, fontWeight: FontWeight.w700));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const _Field({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        obscureText: obscureText,
        onChanged: onChanged,
        validator: validator,
        style: const TextStyle(
            color: Color(0xFF1E2A4A),
            fontSize: 14,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6C8EF5), size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F8), width: 1.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F8), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C8EF5), width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF5350), width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2)),
          errorStyle: const TextStyle(color: Color(0xFFEF5350)),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF5350), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
          GestureDetector(
              onTap: onDismiss,
              child:
                  const Icon(Icons.close, color: Color(0xFFEF5350), size: 16)),
        ]),
      );
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;
  const _Circle({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)));
}
