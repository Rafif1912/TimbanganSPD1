import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// App Colors
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Background & Surface ──────────────────
  static const Color bg = Color(0xFFF0F2FA);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF7F8FD);
  static const Color border = Color(0xFFE4E9F6);

  // ── Primary ───────────────────────────────
  static const Color primary = Color(0xFF5B72F2);
  static const Color primaryDark = Color(0xFF4355D4);
  static const Color primaryLight = Color(0xFFECEFFF);
  static const Color primarySoft = Color(0xFFD0D7FD);

  // ── Accent / Success ──────────────────────
  static const Color accent = Color(0xFF34C99E);
  static const Color accentLight = Color(0xFFDEF7EF);

  // ── Danger ───────────────────────────────
  static const Color danger = Color(0xFFE84545);
  static const Color dangerLight = Color(0xFFFFF0F0);

  // ── Warning ──────────────────────────────
  static const Color warn = Color(0xFFF59E0B);

  // ── Text ─────────────────────────────────
  static const Color textHead = Color(0xFF111827);
  static const Color textBody = Color(0xFF374151);
  static const Color textSub = Color(0xFF6B7A99);
  static const Color textMuted = Color(0xFFB0BDD6);

  // ── Shadow ───────────────────────────────
  static const Color shadow = Color(0x08192A5E);
  static const Color shadowMd = Color(0x145B72F2);
}

// ─────────────────────────────────────────────
// Line Colors
// ─────────────────────────────────────────────
class LineColors {
  LineColors._();

  static const Map<String, Color> _fg = {
    'L1': Color(0xFF5B72F2),
    'L2': Color(0xFF34C99E),
    'L4': Color(0xFFF59E0B),
    'L5': Color(0xFF9B6CF5),
    'L6': Color(0xFFEF5350),
    'L7': Color(0xFF26C6DA),
  };

  static const Color _fallback = Color(0xFF9BA8C7);

  /// Foreground (text/icon) color untuk [line]
  static Color of(String? line) => _fg[(line ?? '').toUpperCase()] ?? _fallback;

  /// Background (container) color untuk [line]
  static Color bgOf(String? line) => of(line).withOpacity(0.12);

  /// Border color untuk [line]
  static Color borderOf(String? line) => of(line).withOpacity(0.25);
}
