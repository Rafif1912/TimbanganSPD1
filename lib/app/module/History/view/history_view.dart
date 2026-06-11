import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timbangan_spd/app/core/theme/app_colors.dart';
import 'package:timbangan_spd/app/core/utils/app_constants.dart';
import 'package:timbangan_spd/app/models/weight_record_model.dart';
import 'package:timbangan_spd/app/module/History/controller/history_controller.dart';
import 'package:timbangan_spd/app/widget/app_widget.dart';
import 'package:timbangan_spd/sidebar.dart';

// ── Responsive Breakpoints ────────────────────────────────────────────────────
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}

T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  required T desktop,
}) {
  if (ResponsiveBreakpoints.isMobile(context)) return mobile;
  if (ResponsiveBreakpoints.isTablet(context) && tablet != null) return tablet;
  return desktop;
}

// ── Constants ──────────────────────────────────────────────────────────────────
const double _kHPad = 20.0;
const _kReset = '__RESET__';

// ── Helper format angka ────────────────────────────────────────────────────────
final _numFmt = NumberFormat('#,##0.##', 'id_ID');
final _shortFmt = DateFormat('dd MMM yy', 'id_ID');
final _longFmt = DateFormat('dd MMM yyyy', 'id_ID');

String _wFmt(double kg) {
  if (kg.abs() >= 1000) {
    return '${NumberFormat('#,##0.###', 'id_ID').format(kg / 1000)} t';
  }
  return '${_numFmt.format(kg)} kg';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

// ══════════════════════════════════════════════════════════════════════════════
// DATE RANGE PICKER — result class
// ══════════════════════════════════════════════════════════════════════════════
class _RangeResult {
  final DateTime? start;
  final DateTime? end;
  final bool cleared;
  const _RangeResult({this.start, this.end, this.cleared = false});
}

// ══════════════════════════════════════════════════════════════════════════════
// DATE RANGE PICKER BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class DateRangePickerBtn extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<_RangeResult?> onChanged;
  final double height;

  const DateRangePickerBtn({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
    this.height = 40,
  });

  String get _label {
    if (startDate == null) return 'Pilih tanggal';
    final s = _shortFmt.format(startDate!);
    if (endDate == null || _isSameDay(startDate!, endDate!)) return s;
    return '$s  →  ${_shortFmt.format(endDate!)}';
  }

  Future<void> _pick(BuildContext ctx) async {
    final result = await showDialog<_RangeResult>(
      context: ctx,
      barrierColor: Colors.black45,
      builder: (_) => _RangePickerDialog(
        initialStart: startDate,
        initialEnd: endDate,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = startDate != null;
    return GestureDetector(
      onTap: () => _pick(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: hasValue ? AppColors.primarySoft : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_month_outlined,
              color: AppColors.primary, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasValue ? AppColors.primary : AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded,
              size: 16,
              color: hasValue ? AppColors.primary : AppColors.textMuted),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DATE RANGE PICKER DIALOG
// ══════════════════════════════════════════════════════════════════════════════
class _RangePickerDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  const _RangePickerDialog({this.initialStart, this.initialEnd});

  @override
  State<_RangePickerDialog> createState() => _RangePickerDialogState();
}

class _RangePickerDialogState extends State<_RangePickerDialog> {
  late DateTime _viewMonth;
  DateTime? _start;
  DateTime? _end;
  DateTime? _hover;
  bool _selectingEnd = false;

  static final _monthFmt = DateFormat('MMMM yyyy', 'id_ID');
  static const _dowLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  @override
  void initState() {
    super.initState();
    _start =
        widget.initialStart != null ? _midnight(widget.initialStart!) : null;
    _end = widget.initialEnd != null ? _midnight(widget.initialEnd!) : null;
    final base = _start ?? DateTime.now();
    _viewMonth = DateTime(base.year, base.month);
    if (_start != null && _end != null) _selectingEnd = false;
    if (_start != null && _end == null) _selectingEnd = true;
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (!_selectingEnd || _start == null) {
        _start = day;
        _end = null;
        _selectingEnd = true;
        _hover = null;
      } else {
        if (_isSameDay(day, _start!)) {
          _end = day;
        } else if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day;
        }
        _selectingEnd = false;
        _hover = null;
      }
    });
  }

  void _applyAndClose(DateTime start, DateTime end) {
    Navigator.pop(context, _RangeResult(start: start, end: end));
  }

  void _setToday() {
    final t = _midnight(DateTime.now());
    _applyAndClose(t, t);
  }

  void _setLast(int days) {
    final today = _midnight(DateTime.now());
    _applyAndClose(today.subtract(Duration(days: days)), today);
  }

  void _setThisMonth() {
    final now = DateTime.now();
    _applyAndClose(DateTime(now.year, now.month, 1), _midnight(now));
  }

  void _confirm() {
    if (_start == null) return;
    Navigator.pop(context, _RangeResult(start: _start, end: _end ?? _start));
  }

  void _clear() => Navigator.pop(context, const _RangeResult(cleared: true));

  String get _headerSub {
    if (_start == null) return 'Pilih tanggal mulai';
    if (_selectingEnd)
      return 'Dari: ${_longFmt.format(_start!)} — pilih akhir';
    if (_end == null || _isSameDay(_start!, _end!)) {
      return _longFmt.format(_start!);
    }
    return '${_longFmt.format(_start!)}  →  ${_longFmt.format(_end!)}';
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startDow = firstDay.weekday % 7;
    final today = _midnight(DateTime.now());
    final effectiveEnd = (_selectingEnd && _hover != null) ? _hover : _end;

    DateTime? lo, hi;
    if (_start != null && effectiveEnd != null) {
      final earlier =
          _start!.isBefore(effectiveEnd) ? _start! : effectiveEnd!;
      final later =
          _start!.isBefore(effectiveEnd) ? effectiveEnd! : _start!;
      lo = earlier;
      hi = later;
    } else if (_start != null) {
      lo = hi = _start;
    }

    final cells = <Widget>[];

    for (int i = 0; i < startDow; i++) {
      cells.add(const SizedBox());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_viewMonth.year, _viewMonth.month, d);
      final isFuture = day.isAfter(today);
      final isStart = _start != null && _isSameDay(day, _start!);
      final isEnd = effectiveEnd != null && _isSameDay(day, effectiveEnd!);
      final inRange = lo != null &&
          hi != null &&
          day.isAfter(lo!) &&
          day.isBefore(hi!);
      final isToday = _isSameDay(day, today);
      final isSingleDay =
          lo != null && hi != null && _isSameDay(lo!, hi!);

      BorderRadius radius = BorderRadius.circular(7);
      if (!isSingleDay) {
        if (isStart && !isEnd) {
          radius =
              const BorderRadius.horizontal(left: Radius.circular(7));
        } else if (isEnd && !isStart) {
          radius =
              const BorderRadius.horizontal(right: Radius.circular(7));
        } else if (inRange) {
          radius = BorderRadius.zero;
        }
      }

      Color? bg;
      Color textColor = AppColors.textBody;
      FontWeight fw = FontWeight.w400;

      if (!isFuture) {
        if (isStart || isEnd) {
          bg = AppColors.primary;
          textColor = Colors.white;
          fw = FontWeight.w800;
        } else if (inRange) {
          bg = AppColors.primaryLight;
          textColor = AppColors.primary;
          fw = FontWeight.w500;
        } else if (isToday) {
          textColor = AppColors.primary;
          fw = FontWeight.w700;
        }
      } else {
        textColor = AppColors.textMuted;
      }

      cells.add(
        MouseRegion(
          onEnter: (_) {
            if (_selectingEnd && !isFuture) {
              setState(() => _hover = day);
            }
          },
          child: GestureDetector(
            onTap: isFuture ? null : () => _onDayTap(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              alignment: Alignment.center,
              height: 34,
              decoration: BoxDecoration(color: bg, borderRadius: radius),
              child: Text(
                '$d',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: fw,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _viewMonth.isBefore(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 20 : 60,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B8EFF), Color(0xFF4F69F5)],
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.date_range_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Rentang Tanggal',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    Text(
                      _headerSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                // Row(children: [
                //   _QuickBtn('Hari ini', onTap: _setToday),
                //   const SizedBox(width: 6),
                //   _QuickBtn('7 Hari', onTap: () => _setLast(6)),
                //   const SizedBox(width: 6),
                //   _QuickBtn('30 Hari', onTap: () => _setLast(29)),
                //   const SizedBox(width: 6),
                //   _QuickBtn('Bulan ini', onTap: _setThisMonth),
                // ]),
                // const SizedBox(height: 12),
                // const Divider(height: 1, color: AppColors.border),
                // const SizedBox(height: 12),
                Row(children: [
                  _CalNavBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => setState(() {
                      _viewMonth =
                          DateTime(_viewMonth.year, _viewMonth.month - 1);
                    }),
                  ),
                  Expanded(
                    child: Text(
                      _monthFmt.format(_viewMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textHead,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  _CalNavBtn(
                    icon: Icons.chevron_right_rounded,
                    enabled: _canGoNext,
                    onTap: () => setState(() {
                      _viewMonth =
                          DateTime(_viewMonth.year, _viewMonth.month + 1);
                    }),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(
                  children: _dowLabels
                      .map((d) => Expanded(
                            child: Text(d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                _buildCalendar(),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                Row(children: [
                  TextButton(
                    onPressed: _clear,
                    child: const Text('Reset',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSub,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _start != null ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Terapkan',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
}

class _CalNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _CalNavBtn(
      {required this.icon, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon,
              size: 18,
              color: enabled ? AppColors.textSub : AppColors.textMuted),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// HISTORY VIEW
// ══════════════════════════════════════════════════════════════════════════════
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HistoryController>();
    return ResponsiveScaffold(
      title: 'Riwayat',
      child: Column(children: [
        _TopBar(ctrl: ctrl),
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) return const AppLoadingView();
            if (!ctrl.hasSearched.value) {
              return const AppEmptyView(
                  message: 'Tentukan filter lalu tekan Tampilkan Data');
            }
            if (ctrl.filteredRecords.isEmpty) {
              return AppEmptyView(
                  message: ctrl.errorMessage.value ??
                      'Tidak ada data untuk filter ini.');
            }
            return _ContentArea(ctrl: ctrl);
          }),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ══════════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final HistoryController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final paddingHorizontal =
        responsiveValue(context, mobile: 12.0, tablet: 20.0, desktop: 32.0);
    final paddingVertical =
        responsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 16.0);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal, vertical: paddingVertical),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: isMobile
          ? _MobileTopBar(ctrl: ctrl)
          : _DesktopTopBar(ctrl: ctrl),
    );
  }
}

void _applyRange(HistoryController ctrl, _RangeResult? result) {
  if (result == null) return;
  if (result.cleared) {
    ctrl.setStartDate(null);
    ctrl.setEndDate(null);
    return;
  }
  if (result.start != null) {
    ctrl.setStartDate(result.start!);
    ctrl.setEndDate(result.end ?? result.start!);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE TOP BAR
// ══════════════════════════════════════════════════════════════════════════════
class _MobileTopBar extends StatelessWidget {
  final HistoryController ctrl;
  const _MobileTopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = ctrl.isLoading.value;
      final source = ctrl.selectedSource.value;
      final hasExtraFilter =
          ctrl.filter.value.line != null || ctrl.filter.value.shift != null;

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isSmallPhone = width < 380;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateRangePickerBtn(
                startDate: ctrl.startDate.value,
                endDate: ctrl.endDate.value,
                onChanged: (r) => _applyRange(ctrl, r),
              ),
              const SizedBox(height: 8),
              if (isSmallPhone)
                Column(
                  children: [
                    Row(children: [
                      Expanded(
                          child: _SourceToggle(
                        selected: source,
                        onChanged: ctrl.setSource,
                      )),
                      const SizedBox(width: 6),
                      _FilterBtn(ctrl: ctrl, hasActive: hasExtraFilter),
                      const SizedBox(width: 6),
                      _SearchBtnCompact(ctrl: ctrl, loading: loading),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _ExcelBtnMobile(ctrl: ctrl),
                      const SizedBox(width: 6),
                      _SummaryBtn(ctrl: ctrl, compact: true),
                      const Spacer(),
                      if (ctrl.lastUpdated.value != null)
                        Text(
                          'Update: ${DateFormat('HH:mm:ss').format(ctrl.lastUpdated.value!)}',
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500),
                        ),
                    ]),
                  ],
                )
              else
                Row(children: [
                  Expanded(
                    child: _SourceToggle(
                      selected: source,
                      onChanged: ctrl.setSource,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _FilterBtn(ctrl: ctrl, hasActive: hasExtraFilter),
                  const SizedBox(width: 6),
                  _SearchBtnCompact(ctrl: ctrl, loading: loading),
                  const SizedBox(width: 6),
                  _ExcelBtnMobile(ctrl: ctrl),
                  const SizedBox(width: 6),
                  _SummaryBtn(ctrl: ctrl, compact: true),
                ]),
              if (ctrl.lastUpdated.value != null && !isSmallPhone)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    if (ctrl.isRefreshing.value) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      'Update: ${DateFormat('HH:mm:ss').format(ctrl.lastUpdated.value!)}',
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    AutoRefreshIndicator(
                        totalSeconds: AppConstants.historyRefreshSeconds),
                  ]),
                ),
            ],
          );
        },
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP TOP BAR
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopTopBar extends StatelessWidget {
  final HistoryController ctrl;
  const _DesktopTopBar({required this.ctrl});

  @override

  @override
  Widget build(BuildContext context) {
    // FIX: gunakan breakpoint yang konsisten dengan sistem responsif yang ada
    final isTablet = ResponsiveBreakpoints.isTablet(context);
     return _TabletTopBar(ctrl: ctrl);
  }
}
//     if (isTablet) {
//       return _TabletTopBar(ctrl: ctrl);
//     }

//     return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
//       Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//               colors: [Color(0xFF7B8EFF), Color(0xFF5B72F2)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight),
//           borderRadius: BorderRadius.circular(10),
//           boxShadow: const [
//             BoxShadow(
//                 color: Color(0x3D5B72F2),
//                 blurRadius: 8,
//                 offset: Offset(0, 3))
//           ],
//         ),
//         child: const Icon(Icons.history_toggle_off_rounded,
//             color: Colors.white, size: 18),
//       ),
//       const SizedBox(width: 12),
//       const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Riwayat Timbangan',
//                 style: TextStyle(
//                     color: AppColors.textHead,
//                     fontSize: 15,
//                     fontWeight: FontWeight.w800)),
//             Text('Data rekap penimbangan per sesi',
//                 style:
//                     TextStyle(color: AppColors.textSub, fontSize: 10.5)),
//           ]),
//       const SizedBox(width: 24),
//       Expanded(
//         child: Obx(() => Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   flex: 4,
//                   child: _FLabel(
//                     'Rentang Tanggal',
//                     DateRangePickerBtn(
//                       startDate: ctrl.startDate.value,
//                       endDate: ctrl.endDate.value,
//                       height: 40,
//                       onChanged: (r) => _applyRange(ctrl, r),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                     flex: 4,
//                     child: _FLabel(
//                         'Line',
//                         _PopupDrop<String>(
//                             value: ctrl.filter.value.line,
//                             hint: 'Semua Line',
//                             items: AppConstants.lines,
//                             display: (l) => l,
//                             onChanged: ctrl.setLine))),
//                 const SizedBox(width: 10),
//                 Expanded(
//                     flex: 4,
//                     child: _FLabel(
//                         'Shift',
//                         _PopupDrop<String>(
//                             value: ctrl.filter.value.shift,
//                             hint: 'Semua Shift',
//                             items: AppConstants.shifts,
//                             display: (s) => 'Shift $s',
//                             onChanged: ctrl.setShift))),
//                 const SizedBox(width: 10),
//                 Expanded(
//                     flex: 4,
//                     child: _FLabel(
//                         'Sumber',
//                         _SourceToggle(
//                           selected: ctrl.selectedSource.value,
//                           onChanged: ctrl.setSource,
//                         ))),
//                 const SizedBox(width: 10),
//                 _SearchBtnDesktop(ctrl: ctrl),
//               ],
//             )),
//       ),
//       const SizedBox(width: 12),
//       Obx(() => ctrl.lastUpdated.value != null
//           ? Padding(
//               padding: const EdgeInsets.only(right: 10),
//               child: Text(
//                 'Update: ${DateFormat('HH:mm:ss').format(ctrl.lastUpdated.value!)}',
//                 style: const TextStyle(
//                     color: AppColors.textMuted,
//                     fontSize: 10.5,
//                     fontWeight: FontWeight.w500),
//               ))
//           : const SizedBox.shrink()),
//       Obx(() => ctrl.isRefreshing.value
//           ? const Padding(
//               padding: EdgeInsets.only(right: 10),
//               child: SizedBox(
//                   width: 14,
//                   height: 14,
//                   child: CircularProgressIndicator(
//                       strokeWidth: 2, color: AppColors.primary)))
//           : const SizedBox.shrink()),
//       Obx(() => ctrl.hasSearched.value
//           ? Padding(
//               padding: const EdgeInsets.only(right: 4),
//               child: AutoRefreshIndicator(
//                   totalSeconds: AppConstants.historyRefreshSeconds))
//           : const SizedBox.shrink()),
//       AppOutlineBtn(
//           icon: Icons.refresh_rounded,
//           label: 'Reset',
//           onTap: ctrl.resetFilter),
//       const SizedBox(width: 8),
//       _ExcelBtnDesktop(ctrl: ctrl),
//       const SizedBox(width: 8),
//       _SummaryBtn(ctrl: ctrl),
//     ]);
//   }
// }

// TABLET TOP BAR
class _TabletTopBar extends StatelessWidget {
  final HistoryController ctrl;
  const _TabletTopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Baris 1: Judul + action buttons ──────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B8EFF), Color(0xFF5B72F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history_toggle_off_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Timbangan',
                    style: TextStyle(
                        color: AppColors.textHead,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text('Data rekap penimbangan per sesi',
                    style:
                        TextStyle(color: AppColors.textSub, fontSize: 10.5)),
              ]),
          const Spacer(),
          Obx(() => ctrl.hasSearched.value
              ? AutoRefreshIndicator(
                  totalSeconds: AppConstants.historyRefreshSeconds)
              : const SizedBox.shrink()),
          const SizedBox(width: 8),
          AppOutlineBtn(
              icon: Icons.refresh_rounded,
              label: 'Reset',
              onTap: ctrl.resetFilter),
          const SizedBox(width: 8),
          _ExcelBtnDesktop(ctrl: ctrl),
          const SizedBox(width: 8),
          _SummaryBtn(ctrl: ctrl),
        ]),

        const SizedBox(height: 12),

        // ── Baris 2: Semua filter dalam SATU ROW sejajar ─────────────
        Obx(() => Row(
              crossAxisAlignment: CrossAxisAlignment.end, // ← kunci sejajar
              children: [
                // Rentang Tanggal — lebih lebar
                Expanded(
                  flex: 3,
                  child: _FLabel(
                    'Rentang Tanggal',
                    DateRangePickerBtn(
                      startDate: ctrl.startDate.value,
                      endDate: ctrl.endDate.value,
                      height: 40,
                      onChanged: (r) => _applyRange(ctrl, r),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Line
                Expanded(
                  flex: 2,
                  child: _FLabel(
                    'Line',
                    _PopupDrop<String>(
                        value: ctrl.filter.value.line,
                        hint: 'Semua Line',
                        items: AppConstants.lines,
                        display: (l) => l,
                        onChanged: ctrl.setLine),
                  ),
                ),
                const SizedBox(width: 8),
                // Shift
                Expanded(
                  flex: 2,
                  child: _FLabel(
                    'Shift',
                    _PopupDrop<String>(
                        value: ctrl.filter.value.shift,
                        hint: 'Semua Shift',
                        items: AppConstants.shifts,
                        display: (s) => 'Shift $s',
                        onChanged: ctrl.setShift),
                  ),
                ),
                const SizedBox(width: 8),
                // Sumber
                Expanded(
                  flex: 2,
                  child: _FLabel(
                    'Sumber',
                    _SourceToggle(
                      selected: ctrl.selectedSource.value,
                      onChanged: ctrl.setSource,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Tombol Tampilkan — align bottom (tanpa label)
                _SearchBtnDesktop(ctrl: ctrl),
              ],
            )),

        // ── Baris 3: Info update + refreshing ────────────────────────
        Obx(() {
          if (ctrl.lastUpdated.value == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              if (ctrl.isRefreshing.value) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: AppColors.primary),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                'Update: ${DateFormat('HH:mm:ss').format(ctrl.lastUpdated.value!)}',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          );
        }),
      ],
    );
  }
}
// ══════════════════════════════════════════════════════════════════════════════
// SOURCE TOGGLE
// ══════════════════════════════════════════════════════════════════════════════
class _SourceToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _SourceToggle({required this.selected, required this.onChanged});

  Color _sourceColor(String src) {
    if (src == 'Auto') return const Color(0xFF0EA5E9);
    if (src == 'Manual') return const Color(0xFF8B5CF6);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(children: [
        for (final src in HistoryController.sources)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(src),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: selected == src
                      ? _sourceColor(src)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(src,
                      style: TextStyle(
                          color: selected == src
                              ? Colors.white
                              : AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FILTER BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _FilterBtn extends StatelessWidget {
  final HistoryController ctrl;
  final bool hasActive;
  const _FilterBtn({required this.ctrl, required this.hasActive});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      color: AppColors.surface,
      elevation: 14,
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Icon(Icons.tune_rounded,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text('Filter Tambahan',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            if (hasActive)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ctrl.setLine(null);
                  ctrl.setShift(null);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Reset',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LINE',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _FilterChip(
                      label: 'Semua',
                      active: ctrl.filter.value.line == null,
                      onTap: () => ctrl.setLine(null),
                    ),
                    ...AppConstants.lines.map((l) => _FilterChip(
                          label: l,
                          active: ctrl.filter.value.line == l,
                          onTap: () => ctrl.setLine(l),
                        )),
                  ]),
                ],
              )),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SHIFT',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _FilterChip(
                      label: 'Semua',
                      active: ctrl.filter.value.shift == null,
                      onTap: () => ctrl.setShift(null),
                    ),
                    ...AppConstants.shifts.map((s) => _FilterChip(
                          label: 'Shift $s',
                          active: ctrl.filter.value.shift == s,
                          onTap: () => ctrl.setShift(s),
                        )),
                  ]),
                ],
              )),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: hasActive ? AppColors.primaryLight : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: hasActive ? AppColors.primarySoft : AppColors.border,
              width: 1.5),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.tune_rounded,
              size: 17,
              color: hasActive ? AppColors.primary : AppColors.textMuted),
          if (hasActive)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
            ),
        ]),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : AppColors.textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// SEARCH BUTTONS
// ══════════════════════════════════════════════════════════════════════════════
class _SearchBtnCompact extends StatelessWidget {
  final HistoryController ctrl;
  final bool loading;
  const _SearchBtnCompact({required this.ctrl, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : ctrl.search,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF7B8EFF), Color(0xFF4F69F5)]),
          color: loading ? AppColors.border : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (loading)
            const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.textSub))
          else
            const Icon(Icons.search_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(loading ? 'Memuat...' : 'Tampilkan',
              style: TextStyle(
                  color: loading ? AppColors.textSub : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _SearchBtnDesktop extends StatelessWidget {
  final HistoryController ctrl;
  const _SearchBtnDesktop({required this.ctrl});

  @override
  Widget build(BuildContext context) => Obx(() {
        final loading = ctrl.isLoading.value;
        return GestureDetector(
          onTap: loading ? null : ctrl.search,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              gradient: loading
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF7B8EFF), Color(0xFF4F69F5)]),
              color: loading ? AppColors.border : null,
              borderRadius: BorderRadius.circular(9),
              boxShadow: loading
                  ? null
                  : const [
                      BoxShadow(
                          color: Color(0x3D5B72F2),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (loading)
                const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.textSub))
              else
                const Icon(Icons.search_rounded,
                    size: 15, color: Colors.white),
              const SizedBox(width: 7),
              Text(loading ? 'Memuat...' : 'Tampilkan',
                  style: TextStyle(
                      color: loading ? AppColors.textSub : Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        );
      });
}

// ══════════════════════════════════════════════════════════════════════════════
// EXCEL BUTTONS
// ══════════════════════════════════════════════════════════════════════════════
bool _needsShift3Modal({
  required String? filterShift,
  required DateTime? startDate,
  required DateTime? endDate,
  required List<WeightRecord> records,
}) {
  if (startDate == null || endDate == null) return false;
  final sameDay = _isSameDay(startDate, endDate);
  if (sameDay) return false;
  if (filterShift != null && filterShift != '3') return false;
  final hasShift3 = records.any((r) {
    final s = r.shift?.toString().trim();
    return s == '3' || s == '3.0';
  });
  return hasShift3;
}

class _ExcelBtnMobile extends StatelessWidget {
  final HistoryController ctrl;
  const _ExcelBtnMobile({required this.ctrl});

  void _handleExportTap(BuildContext context) {
    if (_needsShift3Modal(
        filterShift: ctrl.filter.value.shift,
        startDate: ctrl.startDate.value,
        endDate: ctrl.endDate.value,
        records: ctrl.filteredRecords)) {
      showDialog(
          context: context,
          barrierColor: Colors.black54,
          builder: (_) => _Shift3ExportModal(ctrl: ctrl));
    } else {
      ctrl.exportExcel();
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final exporting = ctrl.isExporting.value;
        final hasData = ctrl.filteredRecords.isNotEmpty;
        return Tooltip(
          message: hasData
              ? 'Export ${ctrl.filteredRecords.length} data ke Excel'
              : 'Tampilkan data terlebih dahulu',
          child: GestureDetector(
            onTap: (!exporting && hasData)
                ? () => _handleExportTap(context)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                gradient: (!exporting && hasData)
                    ? const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF059669)])
                    : null,
                color: (!exporting && hasData) ? null : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: (!exporting && hasData)
                      ? Colors.transparent
                      : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: (!exporting && hasData)
                    ? const [
                        BoxShadow(
                            color: Color(0x3D059669),
                            blurRadius: 6,
                            offset: Offset(0, 3))
                      ]
                    : null,
              ),
              child: Center(
                child: exporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColors.textSub),
                      )
                    : Icon(Icons.file_download_outlined,
                        size: 18,
                        color: (!exporting && hasData)
                            ? Colors.white
                            : AppColors.textMuted),
              ),
            ),
          ),
        );
      });
}

class _ExcelBtnDesktop extends StatelessWidget {
  final HistoryController ctrl;
  const _ExcelBtnDesktop({required this.ctrl});

  void _handleExportTap(BuildContext context) {
    if (_needsShift3Modal(
        filterShift: ctrl.filter.value.shift,
        startDate: ctrl.startDate.value,
        endDate: ctrl.endDate.value,
        records: ctrl.filteredRecords)) {
      showDialog(
          context: context,
          barrierColor: Colors.black54,
          builder: (_) => _Shift3ExportModal(ctrl: ctrl));
    } else {
      ctrl.exportExcel();
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final exporting = ctrl.isExporting.value;
        final hasData = ctrl.filteredRecords.isNotEmpty;
        return Tooltip(
          message: hasData
              ? 'Export ${ctrl.filteredRecords.length} data ke Excel'
              : 'Tampilkan data terlebih dahulu',
          child: GestureDetector(
            onTap: (!exporting && hasData)
                ? () => _handleExportTap(context)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: (!exporting && hasData)
                    ? const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF059669)])
                    : null,
                color: (!exporting && hasData) ? null : AppColors.border,
                borderRadius: BorderRadius.circular(9),
                boxShadow: (!exporting && hasData)
                    ? const [
                        BoxShadow(
                            color: Color(0x3D059669),
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ]
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (exporting)
                  const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppColors.textSub))
                else
                  Icon(Icons.file_download_outlined,
                      size: 15,
                      color: hasData ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 7),
                Text(
                  exporting ? 'Mengekspor...' : 'Excel',
                  style: TextStyle(
                      color: (!exporting && hasData)
                          ? Colors.white
                          : AppColors.textSub,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
        );
      });
}

// SHIFT 3 EXPORT MODAL
class _Shift3ExportModal extends StatelessWidget {
  final HistoryController ctrl;
  const _Shift3ExportModal({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final startDate = ctrl.startDate.value;
    final endDate = ctrl.endDate.value;
    final isMobile = MediaQuery.of(context).size.width < 700;

    final shift3StartStr =
        startDate != null ? '${_longFmt.format(startDate)} 22:00' : '-';
    final shift3EndStr =
        endDate != null ? '${_longFmt.format(endDate)} 07:00' : '-';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 60, vertical: isMobile ? 40 : 80),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x25000000),
                blurRadius: 40,
                offset: Offset(0, 16)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF059669)]),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.file_download_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pilihan Export Excel',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      Text('Data Shift 3 lintas tanggal terdeteksi',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Shift 3 bekerja dari jam 22:00 hingga akhir shift '
                  '(lintas tengah malam). Karena range tanggal berbeda, '
                  'Anda bisa memilih download semua data atau hanya '
                  'periode kerja Shift 3.',
                  style: TextStyle(
                      color: Color(0xFF92400E), fontSize: 11, height: 1.5),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _ExportOption(
                icon: Icons.download_for_offline_outlined,
                iconColor: const Color(0xFF4F69F5),
                bgColor: const Color(0xFFEEF2FF),
                borderColor: const Color(0xFFC7D2FE),
                title: 'Download Semua Data',
                subtitle: 'Sesuai filter yang aktif — semua record '
                    'dari ${startDate != null ? _longFmt.format(startDate) : "-"} '
                    's/d ${endDate != null ? _longFmt.format(endDate) : "-"}',
                badgeText: '${ctrl.filteredRecords.length} sesi',
                badgeColor: const Color(0xFF4F69F5),
                onTap: () {
                  Navigator.pop(context);
                  ctrl.exportExcel();
                },
              ),
              const SizedBox(height: 10),
              _ExportOption(
                icon: Icons.nights_stay_outlined,
                iconColor: const Color(0xFF22C55E),
                bgColor: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
                title: 'Download Shift 3 (22:00 – 07:00)',
                subtitle: 'Hanya data Shift 3 mulai '
                    '$shift3StartStr s/d $shift3EndStr',
                badgeText: 'Shift 3',
                badgeColor: const Color(0xFF059669),
                onTap: () {
                  Navigator.pop(context);
                  ctrl.exportExcelShift3Only();
                },
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ExportOption extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  State<_ExportOption> createState() => _ExportOptionState();
}

class _ExportOptionState extends State<_ExportOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? widget.bgColor : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? widget.borderColor : AppColors.border,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: widget.iconColor.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: widget.borderColor),
              ),
              child:
                  Icon(widget.icon, color: widget.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            color: AppColors.textHead,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(widget.subtitle,
                        style: const TextStyle(
                            color: AppColors.textSub,
                            fontSize: 10.5,
                            height: 1.4)),
                  ]),
            ),
            const SizedBox(width: 10),
            Column(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: widget.badgeColor.withOpacity(0.25)),
                ),
                child: Text(widget.badgeText,
                    style: TextStyle(
                        color: widget.badgeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 6),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: widget.iconColor),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUMMARY BUTTON & MODAL
// ══════════════════════════════════════════════════════════════════════════════
class _SummaryBtn extends StatelessWidget {
  final HistoryController ctrl;
  final bool compact;
  const _SummaryBtn({required this.ctrl, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasData = ctrl.filteredRecords.isNotEmpty;
      return Tooltip(
        message: hasData
            ? 'Total Rec per Line & Shift'
            : 'Tampilkan data terlebih dahulu',
        child: GestureDetector(
          onTap: hasData ? () => _showModal(context) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            width: compact ? 40 : null,
            padding: compact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: hasData
                  ? const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                  : null,
              color: hasData ? null : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: hasData ? Colors.transparent : AppColors.border,
                width: 1.5,
              ),
              boxShadow: hasData
                  ? const [
                      BoxShadow(
                          color: Color(0x3DD97706),
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ]
                  : null,
            ),
            child: compact
                ? Center(
                    child: Icon(Icons.table_chart_rounded,
                        size: 18,
                        color:
                            hasData ? Colors.white : AppColors.textMuted),
                  )
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.table_chart_rounded,
                        size: 15,
                        color:
                            hasData ? Colors.white : AppColors.textMuted),
                    const SizedBox(width: 7),
                    Text('Per Line',
                        style: TextStyle(
                            color:
                                hasData ? Colors.white : AppColors.textSub,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700)),
                  ]),
          ),
        ),
      );
    });
  }

  void _showModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SummaryModal(records: ctrl.filteredRecords),
    );
  }
}

class _SummaryModal extends StatelessWidget {
  final List<WeightRecord> records;
  const _SummaryModal({required this.records});

  Map<String, Map<String, Map<String, double>>> _buildSummary() {
    final Map<String, Map<String, List<WeightRecord>>> grouped = {};
    for (final r in records) {
      final line = r.line ?? 'Unknown';
      final shift = r.shift ?? '-';
      grouped.putIfAbsent(line, () => {});
      grouped[line]!.putIfAbsent(shift, () => []);
      grouped[line]![shift]!.add(r);
    }
    final Map<String, Map<String, Map<String, double>>> result = {};
    grouped.forEach((line, shifts) {
      result[line] = {};
      shifts.forEach((shift, recs) {
        result[line]![shift] = {
          'realASum': recs.fold(0.0, (s, r) => s + r.realWeightA),
          'realBSum': recs.fold(0.0, (s, r) => s + r.realWeightB),
          'count': recs.length.toDouble(),
        };
      });
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _buildSummary();
    final sortedLines = summary.keys.toList()..sort();
    final isMobile = MediaQuery.of(context).size.width < 700;

    double grandRealA = 0, grandRealB = 0;
    int grandCount = 0;
    for (final line in sortedLines) {
      for (final shift in summary[line]!.keys) {
        grandRealA += summary[line]![shift]!['realASum']!;
        grandRealB += summary[line]![shift]!['realBSum']!;
        grandCount += summary[line]![shift]!['count']!.toInt();
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 40, vertical: isMobile ? 20 : 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 860),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000),
                blurRadius: 40,
                offset: Offset(0, 16)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.table_chart_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total per Line & Shift',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Text('Rekap produksi berdasarkan line dan shift',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.functions_rounded,
                                  color: Color(0xFFD97706), size: 16),
                              const SizedBox(width: 8),
                              const Text('Grand Total',
                                  style: TextStyle(
                                      color: Color(0xFF92400E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                              const Spacer(),
                              _GrandChip('$grandCount sesi',
                                  const Color(0xFFF59E0B)),
                            ]),
                            const SizedBox(height: 10),
                            Row(children: [
                              _GrandChip('Real A: ${_wFmt(grandRealA)}',
                                  const Color(0xFF8B5CF6)),
                              const SizedBox(width: 8),
                              _GrandChip('Real B: ${_wFmt(grandRealB)}',
                                  const Color(0xFF10B981)),
                            ]),
                          ],
                        )
                      : Row(children: [
                          const Icon(Icons.functions_rounded,
                              color: Color(0xFFD97706), size: 16),
                          const SizedBox(width: 10),
                          const Text('Grand Total',
                              style: TextStyle(
                                  color: Color(0xFF92400E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          _GrandChip(
                              '$grandCount sesi', const Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          _GrandChip('Real A: ${_wFmt(grandRealA)}',
                              const Color(0xFF8B5CF6)),
                          const SizedBox(width: 8),
                          _GrandChip('Real B: ${_wFmt(grandRealB)}',
                              const Color(0xFF10B981)),
                        ]),
                ),
                ...sortedLines.map((line) {
                  final shifts = summary[line]!;
                  final sortedShifts = shifts.keys.toList()..sort();
                  final lineColor = LineColors.of(line);

                  double lineTotalRealA = 0, lineTotalRealB = 0;
                  int lineTotalCount = 0;
                  for (final s in sortedShifts) {
                    lineTotalRealA += shifts[s]!['realASum']!;
                    lineTotalRealB += shifts[s]!['realBSum']!;
                    lineTotalCount += shifts[s]!['count']!.toInt();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: lineColor.withOpacity(0.25), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: lineColor.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: lineColor.withOpacity(0.07),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          border: Border(
                              bottom: BorderSide(
                                  color: lineColor.withOpacity(0.15))),
                        ),
                        child: Row(children: [
                          LineBadge(line: line, fontSize: 11),
                          const SizedBox(width: 10),
                          Text('$lineTotalCount sesi',
                              style: TextStyle(
                                  color: lineColor.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(children: const [
                          Expanded(
                              flex: 2,
                              child: Text('SHIFT',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5))),
                          Expanded(
                              flex: 1,
                              child: Text('SESI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5))),
                          Expanded(
                              flex: 3,
                              child: Text('REAL A\n(SUM)',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Color(0xFF8B5CF6),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5))),
                          Expanded(
                              flex: 3,
                              child: Text('REAL B\n(SUM)',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5))),
                        ]),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      ...sortedShifts.asMap().entries.map((e) {
                        final i = e.key;
                        final shift = e.value;
                        final d = shifts[shift]!;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? AppColors.surface
                                : AppColors.surfaceAlt,
                            border: const Border(
                                bottom: BorderSide(
                                    color: AppColors.border, width: 0.8)),
                          ),
                          child: Row(children: [
                            Expanded(
                                flex: 2,
                                child:
                                    ShiftBadge(shift: shift, fontSize: 10)),
                            Expanded(
                              flex: 1,
                              child: Text('${d['count']!.toInt()}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.textSub,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                _numFmt.format(d['realASum']),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: d['realASum']! < 0
                                        ? AppColors.danger
                                        : const Color(0xFF8B5CF6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                _numFmt.format(d['realBSum']),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: d['realBSum']! < 0
                                        ? AppColors.danger
                                        : const Color(0xFF10B981),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ]),
                        );
                      }),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: lineColor.withOpacity(0.05),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12)),
                          border: Border(
                              top: BorderSide(
                                  color: lineColor.withOpacity(0.2),
                                  width: 1.5)),
                        ),
                        child: Row(children: [
                          Expanded(
                            flex: 2,
                            child: Text('Total $line',
                                style: TextStyle(
                                    color: lineColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('$lineTotalCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: lineColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _numFmt.format(lineTotalRealA),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: lineTotalRealA < 0
                                      ? AppColors.danger
                                      : const Color(0xFF8B5CF6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _numFmt.format(lineTotalRealB),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: lineTotalRealB < 0
                                      ? AppColors.danger
                                      : const Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _GrandChip extends StatelessWidget {
  final String label;
  final Color color;
  const _GrandChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800)),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// FORM HELPERS
// ══════════════════════════════════════════════════════════════════════════════
class _FLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const _FLabel(this.label, this.child);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
          const SizedBox(height: 5),
          child,
        ],
      );
}

class _PopupDrop<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;

  const _PopupDrop({
    required this.value,
    required this.hint,
    required this.items,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = value != null ? display(value as T) : hint;
    final isEmpty = value == null;

    return PopupMenuButton<String>(
      offset: const Offset(0, 46),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      elevation: 12,
      onSelected: (raw) {
        if (raw == _kReset) {
          onChanged(null);
        } else {
          onChanged(items.firstWhere((e) => e.toString() == raw));
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: _kReset,
          child: Row(children: [
            const Icon(Icons.layers_clear_rounded,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(hint,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        const PopupMenuDivider(height: 1),
        ...items.map((item) {
          final sel = item == value;
          return PopupMenuItem<String>(
            value: item.toString(),
            child: Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(display(item),
                  style: TextStyle(
                      color: sel ? AppColors.primary : AppColors.textBody,
                      fontSize: 13,
                      fontWeight:
                          sel ? FontWeight.w700 : FontWeight.w500)),
            ]),
          );
        }),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: isEmpty ? AppColors.border : AppColors.primarySoft,
              width: 1.5),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color:
                        isEmpty ? AppColors.textMuted : AppColors.primary,
                    fontSize: 12.5,
                    fontWeight:
                        isEmpty ? FontWeight.w500 : FontWeight.w700)),
          ),
          Icon(
              isEmpty
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.tune_rounded,
              color: isEmpty ? AppColors.textMuted : AppColors.primary,
              size: 16),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONTENT AREA
// ══════════════════════════════════════════════════════════════════════════════
class _ContentArea extends StatelessWidget {
  final HistoryController ctrl;
  const _ContentArea({required this.ctrl});

  static Map<String, dynamic> _calcGrandTotal(List<WeightRecord> records) {
    double totalRealA = 0, totalRealB = 0;
    for (final r in records) {
      totalRealA += r.realWeightA;
      totalRealB += r.realWeightB;
    }
    return {
      'totalRealA': totalRealA,
      'totalRealB': totalRealB,
      'totalSesi': records.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return Obx(() {
      final records = ctrl.filteredRecords;
      final gt = _calcGrandTotal(records);
      final totalRealA = gt['totalRealA'] as double;
      final totalRealB = gt['totalRealB'] as double;
      final totalSesi = gt['totalSesi'] as int;

      if (isMobile) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GrandTotalBar(
                  totalRealA: totalRealA,
                  totalRealB: totalRealB,
                  totalSesi: totalSesi),
              const SizedBox(height: 10),
              _SectionLabel(
                  icon: Icons.history_rounded,
                  label: 'Riwayat Data Timbangan',
                  color: const Color(0xFF7B8EFF)),
              const SizedBox(height: 10),
              _MobileRecordList(records: records),
              const SizedBox(height: 16),
            ],
          ),
        );
      }

      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _GrandTotalBar(
              totalRealA: totalRealA,
              totalRealB: totalRealB,
              totalSesi: totalSesi),
        ),
        Expanded(child: _PaginatedTable(records: records)),
      ]);
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GRAND TOTAL BAR
// ══════════════════════════════════════════════════════════════════════════════
class _GrandTotalBar extends StatelessWidget {
  final double totalRealA, totalRealB;
  final int totalSesi;
  const _GrandTotalBar({
    required this.totalRealA,
    required this.totalRealB,
    required this.totalSesi,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    // FIX: gunakan LayoutBuilder agar chip tidak overflow pada lebar sembarang
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x18F59E0B),
              blurRadius: 8,
              offset: Offset(0, 3))
        ],
      ),
      // FIX: pakai LayoutBuilder supaya tahu lebar tepat, bukan asumsi mobile/desktop
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.functions_rounded,
                    size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                const Text('Grand Total',
                    style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                _TotalChip(
                    label: '$totalSesi sesi',
                    color: const Color(0xFFF59E0B)),
              ]),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TotalChip(
                      label: 'Real A: ${_wFmt(totalRealA)}',
                      color: const Color(0xFF8B5CF6)),
                  _TotalChip(
                      label: 'Real B: ${_wFmt(totalRealB)}',
                      color: const Color(0xFF10B981)),
                ],
              ),
            ],
          );
        }
        return Row(children: [
          const Icon(Icons.functions_rounded,
              size: 15, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          const Text('Grand Total',
              style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          _TotalChip(
              label: '$totalSesi sesi', color: const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _TotalChip(
              label: 'Real A: ${_wFmt(totalRealA)}',
              color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 8),
          _TotalChip(
              label: 'Real B: ${_wFmt(totalRealB)}',
              color: const Color(0xFF10B981)),
        ]);
      }),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TotalChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      );
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.textHead,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ]);
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE RECORD LIST
// ══════════════════════════════════════════════════════════════════════════════
class _MobileRecordList extends StatefulWidget {
  final List<WeightRecord> records;
  const _MobileRecordList({required this.records});

  @override
  State<_MobileRecordList> createState() => _MobileRecordListState();
}

class _MobileRecordListState extends State<_MobileRecordList> {
  int _page = 1;
  static const _perPage = 10;

  int get _totalPages =>
      (widget.records.length / _perPage).ceil().clamp(1, 99999);

  List<WeightRecord> get _pageRecords {
    final start = (_page - 1) * _perPage;
    final end = (start + _perPage).clamp(0, widget.records.length);
    return widget.records.sublist(start, end);
  }

  @override
  void didUpdateWidget(_MobileRecordList old) {
    super.didUpdateWidget(old);
    if (old.records != widget.records) setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) {
    final recs = _pageRecords;
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primarySoft),
        ),
        child: Row(children: [
          const Icon(Icons.functions_rounded,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('${widget.records.length} sesi',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
      ...recs.asMap().entries.map((e) => _MobileRecordCard(
            record: e.value,
            index: (_page - 1) * _perPage + e.key + 1,
          )),
      if (_totalPages > 1)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavBtn2(
                    icon: Icons.chevron_left_rounded,
                    enabled: _page > 1,
                    onTap: () => setState(() => _page--)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_page / $_totalPages',
                    style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                _NavBtn2(
                    icon: Icons.chevron_right_rounded,
                    enabled: _page < _totalPages,
                    onTap: () => setState(() => _page++)),
              ]),
        ),
    ]);
  }
}

class _MobileRecordCard extends StatelessWidget {
  final WeightRecord record;
  final int index;
  const _MobileRecordCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final r = record;
    final isAuto = r.source == 'Auto';
    final sourceColor =
        isAuto ? const Color(0xFF0EA5E9) : const Color(0xFF8B5CF6);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isSmallPhone ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(7)),
            child: Center(
              child: Text('$index',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd MMM yyyy').format(r.dbTime),
                      style: const TextStyle(
                          color: AppColors.textHead,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text(DateFormat('HH:mm:ss').format(r.dbTime),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sourceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: sourceColor.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      color: sourceColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(r.source,
                  style: TextStyle(
                      color: sourceColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LineBadge(line: r.line, fontSize: 10),
            ShiftBadge(shift: r.shift, fontSize: 10),
          ],
        ),
        const SizedBox(height: 8),
        // FIX: selalu pakai Column untuk weight cells supaya tidak overflow
        // di semua ukuran layar mobile
        Column(
          children: [
            Row(children: [
              _WeightCell('Real A', r.realWeightA, const Color(0xFF0891B2)),
              _WeightCell('Real B', r.realWeightB, const Color(0xFF0891B2)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              _WeightCell(
                  'Real Total', r.totalRealWeight, const Color(0xFF0891B2)),
              // FIX: Expanded kosong agar Real Total tidak stretching penuh
              const Expanded(child: SizedBox()),
            ]),
          ],
        ),
      ]),
    );
  }
}

class _WeightCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _WeightCell(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  _numFmt.format(value),
                  style: TextStyle(
                      color: value < 0 ? AppColors.danger : color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
        ),
      );
}

class _NavBtn2 extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn2(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primaryLight : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color:
                    enabled ? AppColors.primarySoft : AppColors.border),
          ),
          child: Icon(icon,
              size: 20,
              color: enabled ? AppColors.primary : AppColors.textMuted),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP PAGINATED TABLE
// ══════════════════════════════════════════════════════════════════════════════
class _PaginatedTable extends StatefulWidget {
  final List<WeightRecord> records;
  const _PaginatedTable({required this.records});

  @override
  State<_PaginatedTable> createState() => _PaginatedTableState();
}

class _PaginatedTableState extends State<_PaginatedTable> {
  int _page = 1;
  int _rowsPerPage = AppConstants.defaultRowsPerPage;
  final ScrollController _hScrollController = ScrollController();
  final ScrollController _vScrollController = ScrollController();

  // FIX: lebar minimum tabel — di bawah ini scroll horizontal aktif
  static const double _tableMinWidth = 720.0;

  int get _totalPages =>
      (widget.records.length / _rowsPerPage).ceil().clamp(1, 99999);

  List<WeightRecord> get _pageRecords {
    final start = (_page - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, widget.records.length);
    return widget.records.sublist(start, end);
  }

  @override
  void didUpdateWidget(_PaginatedTable old) {
    super.didUpdateWidget(old);
    if (old.records.length != widget.records.length) {
      setState(() => _page = 1);
    }
  }

  @override
  void dispose() {
    _hScrollController.dispose();
    _vScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageRecs = _pageRecords;
    final isTablet = ResponsiveBreakpoints.isTablet(context);

    return Column(children: [
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              isTablet ? 16 : 20, 14, isTablet ? 16 : 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 20,
                    offset: Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(children: [
                // FIX: header ikut scroll horizontal bersama body
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // FIX: gunakan lebar kontainer yang tersedia, bukan MediaQuery layar
                      final tableWidth =
                          constraints.maxWidth > _tableMinWidth
                              ? constraints.maxWidth
                              : _tableMinWidth;
                      return SingleChildScrollView(
                        controller: _hScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Column(children: [
                            const _TableHeader(),
                            Expanded(
                              child: ListView.builder(
                                controller: _vScrollController,
                                itemCount: pageRecs.length,
                                itemBuilder: (_, i) => _TRow(
                                  record: pageRecs[i],
                                  index: (_page - 1) * _rowsPerPage + i + 1,
                                  isEven: i.isEven,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      _PaginationBar(
        page: _page,
        totalPages: _totalPages,
        totalRows: widget.records.length,
        rowsPerPage: _rowsPerPage,
        onPageChanged: (p) => setState(() => _page = p),
        onRowsPerPageChanged: (r) => setState(() {
          _rowsPerPage = r;
          _page = 1;
        }),
      ),
    ]);
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  static const _hs = TextStyle(
      color: AppColors.textSub,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6);
  static const _realStyle = TextStyle(
      color: Color(0xFF06B6D4),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6);

  Widget _hExp(String t, int flex, [TextAlign a = TextAlign.left]) =>
      Expanded(
          flex: flex,
          child: Text(t.toUpperCase(), textAlign: a, style: _hs));

  Widget _hReal(String t, int flex) => Expanded(
      flex: flex,
      child: Text(t.toUpperCase(),
          textAlign: TextAlign.right, style: _realStyle));

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F9FF),
          border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: _kHPad, vertical: 11),
        child: Row(children: [
          _hExp('No', 1, TextAlign.center),
          const SizedBox(width: 12),
          _hExp('Tanggal / Waktu', 4),
          const SizedBox(width: 12),
          _hExp('Line', 2, TextAlign.center),
          const SizedBox(width: 10),
          _hExp('Shift', 2, TextAlign.center),
          const SizedBox(width: 10),
          _hExp('Sumber', 2, TextAlign.center),
          const SizedBox(width: 10),
          _hReal('Real A', 3),
          _hReal('Real B', 3),
          _hReal('Real Total', 3),
        ]),
      );
}

class _TRow extends StatefulWidget {
  final WeightRecord record;
  final int index;
  final bool isEven;
  const _TRow(
      {required this.record, required this.index, required this.isEven});

  @override
  State<_TRow> createState() => _TRowState();
}

class _TRowState extends State<_TRow> {
  bool _hovered = false;

  Widget _realNum(double val, {int flex = 3}) => Expanded(
        flex: flex,
        child: Text(_numFmt.format(val),
            textAlign: TextAlign.right,
            style: TextStyle(
                color: val < 0
                    ? AppColors.danger
                    : const Color(0xFF0891B2),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final isAuto = r.source == 'Auto';
    final sourceColor =
        isAuto ? const Color(0xFF0EA5E9) : const Color(0xFF8B5CF6);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFFF0F9FF)
              : widget.isEven
                  ? AppColors.surface
                  : AppColors.surfaceAlt,
          border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: _kHPad, vertical: 10),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _hovered
                          ? AppColors.primarySoft
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                        child: Text('${widget.index}',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: AppColors.primarySoft, width: 0.8),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('dd').format(r.dbTime),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1)),
                          Text(
                              DateFormat('MMM')
                                  .format(r.dbTime)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ]),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              DateFormat('dd-MM-yyyy').format(r.dbTime),
                              style: const TextStyle(
                                  color: AppColors.textHead,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.schedule_rounded,
                                size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                                DateFormat('HH:mm:ss').format(r.dbTime),
                                style: const TextStyle(
                                    color: AppColors.textSub,
                                    fontSize: 11)),
                          ]),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                  flex: 2,
                  child: Center(child: LineBadge(line: r.line))),
              const SizedBox(width: 10),
              Expanded(
                  flex: 2,
                  child: Center(child: ShiftBadge(shift: r.shift))),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: sourceColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sourceColor.withOpacity(0.3), width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: sourceColor,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(r.source,
                          style: TextStyle(
                              color: sourceColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _realNum(r.realWeightA),
              _realNum(r.realWeightB),
              _realNum(r.totalRealWeight),
            ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGINATION BAR
// ══════════════════════════════════════════════════════════════════════════════
class _PaginationBar extends StatelessWidget {
  final int page, totalPages, totalRows, rowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalRows,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = ((page - 1) * rowsPerPage + 1).clamp(1, totalRows);
    final end = (page * rowsPerPage).clamp(1, totalRows);
    // FIX: gunakan LayoutBuilder untuk menentukan layout, bukan breakpoint layar
    // Pagination bar berada di dalam area konten yang sudah ter-padding,
    // jadi lebarnya bisa berbeda dengan lebar layar
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          return Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavBtn(
                    icon: Icons.chevron_left_rounded,
                    enabled: page > 1,
                    onTap: () => onPageChanged(page - 1)),
                const SizedBox(width: 8),
                Text('$page / $totalPages',
                    style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                _NavBtn(
                    icon: Icons.chevron_right_rounded,
                    enabled: page < totalPages,
                    onTap: () => onPageChanged(page + 1)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                    text: TextSpan(
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 11),
                  children: [
                    TextSpan(
                        text: '$start–$end',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textBody)),
                    const TextSpan(text: ' dari '),
                    TextSpan(
                        text: '$totalRows',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const TextSpan(text: ' data'),
                  ],
                )),
                const SizedBox(width: 12),
                const Text('Tampilkan:',
                    style: TextStyle(
                        color: AppColors.textSub, fontSize: 11)),
                const SizedBox(width: 6),
                _RowsPopup(
                    value: rowsPerPage,
                    onChanged: onRowsPerPageChanged),
              ],
            ),
          ]);
        }
        return Row(children: [
          RichText(
              text: TextSpan(
            style: const TextStyle(
                color: AppColors.textSub, fontSize: 12),
            children: [
              TextSpan(
                  text: '$start–$end',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody)),
              const TextSpan(text: ' dari '),
              TextSpan(
                  text: '$totalRows',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const TextSpan(text: ' data'),
            ],
          )),
          const Spacer(),
          const Text('Tampilkan:',
              style: TextStyle(
                  color: AppColors.textSub, fontSize: 11.5)),
          const SizedBox(width: 7),
          _RowsPopup(
              value: rowsPerPage, onChanged: onRowsPerPageChanged),
          const SizedBox(width: 16),
          _NavBtn(
              icon: Icons.chevron_left_rounded,
              enabled: page > 1,
              onTap: () => onPageChanged(page - 1)),
          const SizedBox(width: 3),
          ..._pageNums(),
          const SizedBox(width: 3),
          _NavBtn(
              icon: Icons.chevron_right_rounded,
              enabled: page < totalPages,
              onTap: () => onPageChanged(page + 1)),
        ]);
      }),
    );
  }

  List<Widget> _pageNums() {
    final from = (page - 2).clamp(1, totalPages);
    final to = (page + 2).clamp(1, totalPages);
    return [
      for (int p = from; p <= to; p++)
        _PNum(n: p, active: p == page, onTap: () => onPageChanged(p))
    ];
  }
}

class _RowsPopup extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RowsPopup({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
        offset: const Offset(0, -150),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        color: AppColors.surface,
        elevation: 12,
        onSelected: onChanged,
        itemBuilder: (_) => AppConstants.rowsPerPageOptions
            .map((n) => PopupMenuItem<int>(
                  value: n,
                  child: Row(children: [
                    Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: n == value
                                ? AppColors.primary
                                : Colors.transparent)),
                    const SizedBox(width: 10),
                    Text('$n baris',
                        style: TextStyle(
                            color: n == value
                                ? AppColors.primary
                                : AppColors.textBody,
                            fontSize: 12.5,
                            fontWeight: n == value
                                ? FontWeight.w700
                                : FontWeight.w500)),
                  ]),
                ))
            .toList(),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primarySoft),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$value',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                color: AppColors.primary, size: 15),
          ]),
        ),
      );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primaryLight : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    enabled ? AppColors.primarySoft : AppColors.border),
          ),
          child: Icon(icon,
              size: 18,
              color: enabled ? AppColors.primary : AppColors.textMuted),
        ),
      );
}

class _PNum extends StatelessWidget {
  final int n;
  final bool active;
  final VoidCallback onTap;
  const _PNum(
      {required this.n, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF7B8EFF), Color(0xFF4F69F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                : null,
            color: active ? null : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.border),
            boxShadow: active
                ? const [
                    BoxShadow(
                        color: Color(0x3D5B72F2),
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ]
                : null,
          ),
          child: Center(
              child: Text('$n',
                  style: TextStyle(
                      color: active ? Colors.white : AppColors.textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
        ),
      );
}