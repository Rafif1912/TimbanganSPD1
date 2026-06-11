import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:timbangan_spd/app/core/config/env.dart';
import 'package:timbangan_spd/app/models/auth_models.dart';
import 'package:timbangan_spd/app/routes/app_routes.dart';
import 'package:timbangan_spd/app/service/auth_storage_service.dart';
import 'package:timbangan_spd/app/service/session_service.dart';

class LoginController extends GetxController {
  final formKey      = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final isLoading    = false.obs;
  final isLoggedIn   = false.obs;
  final loggedInUser = RxnString();
  final errorMessage = RxnString();
  final showPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkSession();
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  void _checkSession() {
    final token = AuthStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      isLoggedIn.value   = true;
      loggedInUser.value = AuthStorageService.getUsername();
    }
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value    = true;
    errorMessage.value = null;

    try {
      final res = await http
          .post(
            Uri.parse('${Env.mainUrl}/api/Auth/Login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'UsernameOrEmail': usernameCtrl.text.trim(),
              'Password': passwordCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body     = jsonDecode(res.body) as Map<String, dynamic>;
      final status   = body['status'] as Map<String, dynamic>?;
      final code     = status?['code'] as int?;
      final dbStatus = status?['dbStatus'] as int?;
      final message  = status?['message'] as String? ?? 'Terjadi kesalahan';
      final isSuccess = (code == 200) || (dbStatus == 1);

      if (isSuccess && body['data'] != null) {
        final data = LoginResponse.fromJson(
            body['data'] as Map<String, dynamic>);

        AuthStorageService.saveSession(
          accessToken:        data.accessToken,
          refreshToken:       data.refreshToken,
          userId:             data.userId,
          nama:               data.nama,
          username:           data.username,
          email:              data.email,
          role:               data.role,
          accessTokenExpiry:  data.accessTokenExpiry,
          refreshTokenExpiry: data.refreshTokenExpiry,
        );

        isLoggedIn.value   = true;
        loggedInUser.value = data.username;
        isLoading.value    = false;

        await Future.delayed(const Duration(milliseconds: 150));
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        errorMessage.value = message;
        isLoading.value    = false;
      }
    } catch (e) {
      errorMessage.value =
          'Gagal terhubung ke server. Periksa koneksi jaringan.';
      isLoading.value = false;
    }
  }

  // ── LOGOUT — panggil API dulu, baru clear local ──────────────────────
  Future<void> logout() async {
    final token        = AuthStorageService.getAccessToken();
    final refreshToken = AuthStorageService.getRefreshToken();

    // Panggil API logout untuk revoke token di database
    if (token != null && token.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('${Env.mainUrl}/api/Auth/Logout'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              // Kirim refresh token agar hanya token device ini yang di-revoke
              // Kalau mau revoke semua device, kirim body kosong: body: jsonEncode({})
              body: jsonEncode({
                if (refreshToken != null && refreshToken.isNotEmpty)
                  'RefreshToken': refreshToken,
              }),
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // Gagal panggil API tidak masalah — tetap lanjut clear local
        // Misal server mati atau timeout, user tetap bisa logout dari client
      }
    }

    // Clear semua data lokal
    AuthStorageService.clear();
    isLoggedIn.value   = false;
    loggedInUser.value = null;
    errorMessage.value = null;
    usernameCtrl.clear();
    passwordCtrl.clear();
    showPassword.value = false;

    Get.offAllNamed(AppRoutes.login);
  }

  void togglePassword()  => showPassword.value = !showPassword.value;
  void clearError()      => errorMessage.value = null;
  void onFieldChanged()  => clearError();

  bool isSessionValid() {
    final token = AuthStorageService.getAccessToken();
    if (token == null || token.isEmpty) {
      logout();
      return false;
    }
    SessionService.updateLastActivity();
    return true;
  }

  void updateLastActivity() => SessionService.updateLastActivity();
}