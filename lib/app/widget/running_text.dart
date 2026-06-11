import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

// ─────────────────────────────────────────────
// Running Text — Ticker bawah layar
// ─────────────────────────────────────────────
class RunningText extends StatefulWidget {
  const RunningText({super.key});

  @override
  State<RunningText> createState() => _RunningTextState();
}

class _RunningTextState extends State<RunningText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<String> _messages = [
    '📋 Aturan keselamatan kerja adalah alat kerja terbaik. Maka patuhilah!',
    '⚠️ Selalu gunakan APD (Alat Pelindung Diri) saat berada di area produksi.',
    '✅ Laporkan segera timbangan yang tidak berfungsi kepada supervisor.',
    '🔔 Pastikan setiap timbangan terkalibrasi sebelum digunakan.',
    '🏭 Keselamatan adalah tanggung jawab kita bersama. Jaga diri dan rekan kerja!',
    '📊 Pantau berat secara berkala untuk memastikan akurasi produksi.',
    '🚨 Segera laporkan anomali pembacaan timbangan kepada tim teknis.',
  ];

  int _index = 0;
  double _containerWidth = 0;

  String get _dateText =>
      DateFormat('dd MMMM yyyy', 'id').format(DateTime.now());

  String get _currentMessage => _messages[_index];

  double _measureText(String text, BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return tp.width + 80;
  }

  void _startAnimation() {
    if (!mounted) return;
    final textW = _measureText(_currentMessage, context);
    final totalDist = _containerWidth + textW;
    final durationMs = (totalDist / 80 * 1000).toInt();

    _controller.duration = Duration(milliseconds: durationMs);
    _controller.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _messages.length);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _startAnimation();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startAnimation();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A5C38),
            Color(0xFF2E8B5A),
            Color(0xFF4DB87A),
            Color(0xFF7FCA9F),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Row(children: [
        // Tanggal kiri
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF124D2E),
            border:
                Border(right: BorderSide(color: Color(0xFF3DAA6A), width: 1)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_rounded,
                color: Colors.white, size: 13),
            const SizedBox(width: 7),
            Text(
              _dateText,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 14, color: Colors.white24),
            const SizedBox(width: 10),
            const Icon(Icons.article_rounded, color: Colors.white70, size: 13),
          ]),
        ),

        // Running text
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _containerWidth = constraints.maxWidth;
              return ClipRect(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final textW = _measureText(_currentMessage, context);
                    final x = _containerWidth -
                        (_containerWidth + textW) * _controller.value;
                    return Stack(children: [
                      Positioned(
                        left: x,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            _currentMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ]);
                  },
                ),
              );
            },
          ),
        ),

        // Badge INFO kanan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF124D2E),
            border:
                Border(left: BorderSide(color: Color(0xFF3DAA6A), width: 1)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.campaign_rounded, color: Colors.white70, size: 14),
            SizedBox(width: 5),
            Text(
              'INFO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2),
            ),
          ]),
        ),
      ]),
    );
  }
}
