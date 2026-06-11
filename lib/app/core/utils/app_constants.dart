// ─────────────────────────────────────────────
// App Constants
// ─────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  /// Semua line yang tersedia di backend SPDScale
  static const List<String> lines = ['L1', 'L2', 'L4', 'L5', 'L6', 'L7'];

  /// Shift sebagai String agar cocok dengan backend & model
  static const List<String> shifts = ['1', '2', '3'];

  /// Opsi jumlah baris per halaman di tabel history
static const List<int> rowsPerPageOptions = [25, 50, 100];
  // static const int defaultRowsPerPage = 10;
  static const int defaultRowsPerPage = 50;

  /// Auto-refresh interval untuk history view (detik)
  static const int historyRefreshSeconds = 10;
}
