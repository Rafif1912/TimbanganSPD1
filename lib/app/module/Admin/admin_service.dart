import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timbangan_spd/app/core/config/env.dart';
import 'package:timbangan_spd/app/models/auth_models.dart';
import 'package:timbangan_spd/app/service/auth_storage_service.dart';

class AdminService {
  static String get _base => '${Env.mainUrl}/api';

  static Map<String, String> _headers() {
    final token = AuthStorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _safeJson(http.Response res) async {
    final body = res.body.trim();
    if (body.isEmpty) {
      throw switch (res.statusCode) {
        401 => 'Tidak punya akses (401 Unauthorized)',
        403 => 'Akses ditolak (403 Forbidden)',
        404 => 'Endpoint tidak ditemukan (404)',
        500 => 'Server error (500)',
        _   => 'Server error (${res.statusCode})',
      };
    }
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw 'Response tidak valid dari server (${res.statusCode})';
    }
    if (res.statusCode == 403) {
      throw json['status']?['message'] ?? 'Akses ditolak (403 Forbidden)';
    }
    if (res.statusCode == 401) {
      throw json['status']?['message'] ?? 'Tidak punya akses (401 Unauthorized)';
    }
    return json;
  }

  // ─── Users ────────────────────────────────────────────────

  static Future<List<UserListModel>> getAllUsers() async {
    final res = await http
        .get(Uri.parse('$_base/Auth/GetAllUsers'), headers: _headers())
        .timeout(const Duration(seconds: 15));
    final body = await _safeJson(res);
    if ((body['status']?['code'] ?? 0) == 200) {
      return (body['data'] as List).map((e) => UserListModel.fromJson(e)).toList();
    }
    throw body['status']?['message'] ?? 'Gagal mengambil data user';
  }

  static Future<String> createUser({
    required String nama,
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/Auth/CreateUser'),
          headers: _headers(),
          body: jsonEncode({
            'Nama': nama, 'Email': email, 'Username': username,
            'Password': password, 'Role': role,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final body = await _safeJson(res);
    final msg = body['status']?['message'] ?? '';
    if ((body['status']?['code'] ?? 0) == 200) return msg;
    throw msg;
  }

  static Future<void> updateRole(int userId, String role) async {
    final res = await http
        .put(
          Uri.parse('$_base/Auth/UpdateRole'),
          headers: _headers(),
          body: jsonEncode({'UserId': userId, 'Role': role}),
        )
        .timeout(const Duration(seconds: 15));
    final body = await _safeJson(res);
    if ((body['status']?['code'] ?? 0) != 200) {
      throw body['status']?['message'] ?? 'Gagal update role';
    }
  }

  static Future<void> updateStatus(int userId, bool aktif) async {
    final res = await http
        .put(
          Uri.parse('$_base/Auth/UpdateStatus'),
          headers: _headers(),
          body: jsonEncode({'UserId': userId, 'Aktif': aktif}),
        )
        .timeout(const Duration(seconds: 15));
    final body = await _safeJson(res);
    if ((body['status']?['code'] ?? 0) != 200) {
      throw body['status']?['message'] ?? 'Gagal update status';
    }
  }

  // ─── Menus ────────────────────────────────────────────────

  static Future<List<MenuModel>> getAllMenus() async {
    final res = await http
        .get(Uri.parse('$_base/Auth/GetAllMenus'), headers: _headers())
        .timeout(const Duration(seconds: 15));
    final body = await _safeJson(res);
    if ((body['status']?['code'] ?? 0) == 200) {
      return (body['data'] as List).map((e) => MenuModel.fromJson(e)).toList();
    }
    throw body['status']?['message'] ?? 'Gagal mengambil menu';
  }

  static Future<void> updateMenuRoles(int menuId, List<String> roles) async {
    final res = await http
        .put(
          Uri.parse('$_base/Auth/UpdateMenuRoles'),
          headers: _headers(),
          body: jsonEncode({'Id': menuId, 'Roles': roles}),
        )
        .timeout(const Duration(seconds: 15));
    final body = await _safeJson(res);
    if ((body['status']?['code'] ?? 0) != 200) {
      throw body['status']?['message'] ?? 'Gagal update menu roles';
    }
  }

  // ─── Activity Logs ────────────────────────────────────────

  static Future<List<ActivityLogModel>> getActivityLogs({
    int? userId, DateTime? startDate, DateTime? endDate,
  }) async {
    final params = <String, String>{};
    if (userId    != null) params['userId']    = userId.toString();
    if (startDate != null) params['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate   != null) params['endDate']   = endDate.toIso8601String().split('T')[0];

    final uri = Uri.parse('$_base/Auth/GetActivityLogs').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 30));
    final body = await _safeJson(res);
    if ((body['status']?['code'] ?? 0) == 200) {
      return (body['data'] as List).map((e) => ActivityLogModel.fromJson(e)).toList();
    }
    throw body['status']?['message'] ?? 'Gagal mengambil activity log';
  }
}