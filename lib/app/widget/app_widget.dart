import 'package:flutter/material.dart';
import 'package:timbangan_spd/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────
// Line Badge
// ─────────────────────────────────────────────
class LineBadge extends StatelessWidget {
  final String? line;
  final double fontSize;

  const LineBadge({super.key, required this.line, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final label = line ?? '-';
    final color = LineColors.of(line);
    final bg = LineColors.bgOf(line);
    final border = LineColors.borderOf(line);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: color, fontSize: fontSize, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shift Badge
// ─────────────────────────────────────────────
class ShiftBadge extends StatelessWidget {
  final String? shift;
  final double fontSize;

  const ShiftBadge({super.key, required this.shift, this.fontSize = 10.5});

  @override
  Widget build(BuildContext context) {
    // shift "0" dari API = tidak diketahui
    final isUnknown = shift == null || shift == '0' || shift!.isEmpty;
    if (isUnknown) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('—',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: fontSize,
                fontWeight: FontWeight.w700)),
      );
    }
    if (false) {
      return const Text('—',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Text(
        'Shift $shift',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: AppColors.primary,
            fontSize: fontSize,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// App Loading View
// ─────────────────────────────────────────────
class AppLoadingView extends StatelessWidget {
  final String? message;
  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.all(13),
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message ?? 'Memuat data...',
            style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────
// App Empty View
// ─────────────────────────────────────────────
class AppEmptyView extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final IconData icon;

  const AppEmptyView({
    super.key,
    this.message,
    this.subtitle,
    this.icon = Icons.history_rounded,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFECEFFF), Color(0xFFD0D7FD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A5B72F2),
                    blurRadius: 16,
                    offset: Offset(0, 6))
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'Tidak ada data',
            style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            subtitle ?? 'Gunakan filter di atas untuk mencari data',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────
// App Outline Button (dengan hover effect)
// ─────────────────────────────────────────────
class AppOutlineBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AppOutlineBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<AppOutlineBtn> createState() => _AppOutlineBtnState();
}

class _AppOutlineBtnState extends State<AppOutlineBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: _hovered ? AppColors.primarySoft : AppColors.border),
            ),
            child: Row(children: [
              Icon(widget.icon,
                  size: 14,
                  color: _hovered ? AppColors.primary : AppColors.textSub),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                    color: _hovered ? AppColors.primary : AppColors.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ),
      );
}

// ─────────────────────────────────────────────
// Auto Refresh Indicator (countdown ring)
// ─────────────────────────────────────────────
class AutoRefreshIndicator extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback? onRefresh;

  const AutoRefreshIndicator({
    super.key,
    required this.totalSeconds,
    this.onRefresh,
  });

  @override
  State<AutoRefreshIndicator> createState() => _AutoRefreshIndicatorState();
}

class _AutoRefreshIndicatorState extends State<AutoRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final remaining = ((1 - _anim.value) * widget.totalSeconds).ceil();
          return Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: 1 - _anim.value,
                strokeWidth: 2,
                color: AppColors.accent,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${remaining}s',
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ]);
        },
      );
}

// ─────────────────────────────────────────────
// Status Dot dengan efek pulse saat loading
// ─────────────────────────────────────────────
class StatusDot extends StatefulWidget {
  final Color color;
  final bool isLoading;
  const StatusDot({super.key, required this.color, required this.isLoading});

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      );
    }
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
