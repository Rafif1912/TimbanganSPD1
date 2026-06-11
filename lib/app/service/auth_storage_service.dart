// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AuthStorageService {
  AuthStorageService._();

  static const _keyAccessToken   = 'access_token';
  static const _keyRefreshToken  = 'refresh_token';
  static const _keyUserId        = 'user_id';
  static const _keyNama          = 'user_nama';
  static const _keyUsername      = 'user_username';
  static const _keyEmail         = 'user_email';
  static const _keyRole          = 'user_role';
  static const _keyAccessExpiry  = 'access_expiry';
  static const _keyRefreshExpiry = 'refresh_expiry';

  // Cache in-memory sebagai backup jika sessionStorage lambat/kosong
  static String? _cachedToken;
  static String? _cachedRefreshToken;
  static int?    _cachedUserId;
  static String? _cachedNama;
  static String? _cachedUsername;
  static String? _cachedEmail;
  static String? _cachedRole;

  static void saveSession({
    required String   accessToken,
    required String   refreshToken,
    required int      userId,
    required String   nama,
    required String   username,
    required String   email,
    required String   role,
    required DateTime accessTokenExpiry,
    required DateTime refreshTokenExpiry,
  }) {
    // Simpan ke cache in-memory dulu
    _cachedToken        = accessToken;
    _cachedRefreshToken = refreshToken;
    _cachedUserId       = userId;
    _cachedNama         = nama;
    _cachedUsername     = username;
    _cachedEmail        = email;
    _cachedRole         = role;

    // Simpan ke sessionStorage
    final s = html.window.sessionStorage;
    s[_keyAccessToken]   = accessToken;
    s[_keyRefreshToken]  = refreshToken;
    s[_keyUserId]        = userId.toString();
    s[_keyNama]          = nama;
    s[_keyUsername]      = username;
    s[_keyEmail]         = email;
    s[_keyRole]          = role;
    s[_keyAccessExpiry]  = accessTokenExpiry.toUtc().toIso8601String();
    s[_keyRefreshExpiry] = refreshTokenExpiry.toUtc().toIso8601String();
  }

  // Baca dari cache in-memory dulu, fallback ke sessionStorage
  static String? getAccessToken() =>
      _cachedToken ?? html.window.sessionStorage[_keyAccessToken];

  static String? getRefreshToken() =>
      _cachedRefreshToken ?? html.window.sessionStorage[_keyRefreshToken];

  static String? getNama() =>
      _cachedNama ?? html.window.sessionStorage[_keyNama];

  static String? getUsername() =>
      _cachedUsername ?? html.window.sessionStorage[_keyUsername];

  static String? getEmail() =>
      _cachedEmail ?? html.window.sessionStorage[_keyEmail];

  static String? getRole() =>
      _cachedRole ?? html.window.sessionStorage[_keyRole];

  static int? getUserId() {
    if (_cachedUserId != null) return _cachedUserId;
    final v = html.window.sessionStorage[_keyUserId];
    return v != null ? int.tryParse(v) : null;
  }

  static DateTime? getAccessTokenExpiry() {
    final v = html.window.sessionStorage[_keyAccessExpiry];
    if (v == null) return null;
    return DateTime.parse(v).toUtc();
  }

  static DateTime? getRefreshTokenExpiry() {
    final v = html.window.sessionStorage[_keyRefreshExpiry];
    if (v == null) return null;
    return DateTime.parse(v).toUtc();
  }

  static bool get isLoggedIn {
    final token  = getAccessToken();
    final expiry = getAccessTokenExpiry();
    if (token == null || token.isEmpty || expiry == null) return false;
    return expiry.isAfter(DateTime.now().toUtc());
  }

  static void clear() {
    // Bersihkan cache in-memory juga
    _cachedToken        = null;
    _cachedRefreshToken = null;
    _cachedUserId       = null;
    _cachedNama         = null;
    _cachedUsername     = null;
    _cachedEmail        = null;
    _cachedRole         = null;
    html.window.sessionStorage.clear();
  }
}