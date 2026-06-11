// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// ─────────────────────────────────────────────
// Session Service — pakai sessionStorage (web)
// Otomatis hapus saat browser/tab ditutup
// ─────────────────────────────────────────────
class SessionService {
  SessionService._();

  static void set(String key, String value) =>
      html.window.sessionStorage[key] = value;

  static String? get(String key) => html.window.sessionStorage[key];

  static void remove(String key) => html.window.sessionStorage.remove(key);

  static void clear() => html.window.sessionStorage.clear();

  static bool get isLoggedIn =>
      html.window.sessionStorage['isLoggedIn'] == 'true';

  static String? get loggedInUser => html.window.sessionStorage['loggedInUser'];

  /// ✅ Timeout diubah ke 60 menit (1 jam)
  static bool isSessionValid({int timeoutMinutes = 60}) {
    if (!isLoggedIn) return false;
    final lastStr = get('lastActivity');
    if (lastStr == null) return false;
    final diff = DateTime.now().difference(DateTime.parse(lastStr));
    return diff.inMinutes < timeoutMinutes;
  }

  static void updateLastActivity() =>
      set('lastActivity', DateTime.now().toIso8601String());

  static void saveLogin(String username) {
    set('isLoggedIn', 'true');
    set('loggedInUser', username);
    set('loginTime', DateTime.now().millisecondsSinceEpoch.toString());
    updateLastActivity();
  }
}
