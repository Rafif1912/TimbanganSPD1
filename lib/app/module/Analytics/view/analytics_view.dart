import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timbangan_spd/app/core/theme/app_colors.dart';
import 'package:timbangan_spd/app/core/utils/app_constants.dart';
import 'package:timbangan_spd/app/models/analytics_model.dart';
import 'package:timbangan_spd/app/models/weight_record_model.dart';
import 'package:timbangan_spd/app/module/Analytics/controller/analytics_controller.dart';
import 'package:timbangan_spd/app/widget/app_widget.dart';
import 'package:timbangan_spd/sidebar.dart';

// ── Helper format angka ───────────────────────────────────────────────────────
final _numFmt = NumberFormat('#,##0.##', 'id_ID');

String _wFmt(double kg) {
  if (kg.abs() >= 1000) {
    return '${NumberFormat('#,##0.###', 'id_ID').format(kg / 1000)} t';
  }
  return '${_numFmt.format(kg)} kg';
}

// ─────────────────────────────────────────────
// Analytics View
// ─────────────────────────────────────────────
class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Analitik',
      child: Column(children: [
        _TopBar(ctrl: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const AppLoadingView(message: 'Menganalisis data...');
            }
            return _Body(ctrl: controller);
          }),
        ),
      ]),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AnalyticsController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24, vertical: isMobile ? 10 : 14),
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

class _MobileTopBar extends StatelessWidget {
  final AnalyticsController ctrl;
  const _MobileTopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final start   = ctrl.startDate.value;
      final end     = ctrl.endDate.value;
      final loading = ctrl.isLoading.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: _MobileDateBtn(
                label: 'Dari',
                value: start,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: start ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF0EA5E9),
                              onPrimary: Colors.white)),
                      child: child!,
                    ),
                  );
                  if (picked != null) ctrl.setStartDate(picked);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 12, color: AppColors.primary),
              ),
            ),
            Expanded(
              child: _MobileDateBtn(
                label: 'Sampai',
                value: end,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: end ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF0EA5E9),
                              onPrimary: Colors.white)),
                      child: child!,
                    ),
                  );
                  if (picked != null) ctrl.setEndDate(picked);
                },
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _SourceToggle(
              selected: ctrl.selectedSource.value,
              onChanged: ctrl.setSource,
            )),
            const SizedBox(width: 8),
            _SearchBtnCompact(ctrl: ctrl, loading: loading),
          ]),
          if (ctrl.lastUpdated.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                if (ctrl.isRefreshing.value)
                  const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: Color(0xFF0EA5E9)),
                  ),
                if (ctrl.isRefreshing.value) const SizedBox(width: 6),
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
    });
  }
}

class _MobileDateBtn extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _MobileDateBtn(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_month_outlined,
              color: Color(0xFF0EA5E9), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
                Text(
                  value != null
                      ? DateFormat('dd MMM yy', 'id_ID').format(value!)
                      : '—',
                  style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _SearchBtnCompact extends StatelessWidget {
  final AnalyticsController ctrl;
  final bool loading;
  const _SearchBtnCompact({required this.ctrl, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : ctrl.search,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)]),
          color: loading ? AppColors.border : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (loading)
            const SizedBox(
                width: 13, height: 13,
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

class _DesktopTopBar extends StatelessWidget {
  final AnalyticsController ctrl;
  const _DesktopTopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [
            BoxShadow(color: Color(0x440EA5E9), blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 19),
      ),
      const SizedBox(width: 12),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Analitik Produksi',
            style: TextStyle(
                color: AppColors.textHead,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        Text('Ringkasan data timbangan per periode',
            style: TextStyle(color: AppColors.textSub, fontSize: 10.5)),
      ]),
      const SizedBox(width: 24),
      Expanded(
        child: Obx(() => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 5, child: _FLabel('Tanggal Mulai',
                _DateField(value: ctrl.startDate.value, onChanged: ctrl.setStartDate))),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFBFDBFE))),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 13, color: Color(0xFF0EA5E9)),
              ),
            ),
            Expanded(flex: 5, child: _FLabel('Tanggal Akhir',
                _DateField(value: ctrl.endDate.value, onChanged: ctrl.setEndDate))),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: _FLabel('Sumber',
                _SourceToggle(
                  selected: ctrl.selectedSource.value,
                  onChanged: ctrl.setSource,
                ))),
            const SizedBox(width: 14),
            _SearchBtn(ctrl: ctrl),
          ],
        )),
      ),
      const SizedBox(width: 12),
      Obx(() => ctrl.lastUpdated.value != null
          ? Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                'Update: ${DateFormat('HH:mm:ss').format(ctrl.lastUpdated.value!)}',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500),
              ))
          : const SizedBox.shrink()),
      Obx(() => ctrl.isRefreshing.value
          ? const Padding(
              padding: EdgeInsets.only(right: 10),
              child: SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF0EA5E9))))
          : const SizedBox.shrink()),
      Obx(() => ctrl.hasSearched.value
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AutoRefreshIndicator(
                  totalSeconds: AppConstants.historyRefreshSeconds))
          : const SizedBox.shrink()),
    ]);
  }
}

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
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(children: [
        for (final src in AnalyticsController.sources)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(src),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: selected == src ? _sourceColor(src) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(src,
                      style: TextStyle(
                          color: selected == src ? Colors.white : AppColors.textMuted,
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

class _DateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const _DateField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: Color(0xFF0EA5E9), onPrimary: Colors.white)),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_month_outlined,
                color: Color(0xFF0EA5E9), size: 15),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? DateFormat('dd MMM yyyy', 'id_ID').format(value!)
                  : '—',
              style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      );
}

class _SearchBtn extends StatelessWidget {
  final AnalyticsController ctrl;
  const _SearchBtn({required this.ctrl});

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
                      colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)]),
              color: loading ? AppColors.border : null,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (loading)
                const SizedBox(
                    width: 13, height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.textSub))
              else
                const Icon(Icons.search_rounded, size: 15, color: Colors.white),
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

// ── Body — Real Weight vars DIHAPUS ──────────────────────────────────────────
class _Body extends StatelessWidget {
  final AnalyticsController ctrl;
  const _Body({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Obx(() {
      final linePerf  = ctrl.linePerformance.toList();
      final totalProd = ctrl.totalProduction;
      final totalTx   = ctrl.totalTransactions;
      final totalA    = ctrl.totalRecordA;
      final totalB    = ctrl.totalRecordB;
      // totalRealAll / totalRealA / totalRealB → DIHAPUS

      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPI Cards ─────────────────────────────────────────────────
            if (isMobile)
              _MobileKpiCards(
                totalProd: totalProd,
                totalA:    totalA,
                totalB:    totalB,
                totalTx:   totalTx,
              )
            else
              _DesktopKpiCards(
                totalProd: totalProd,
                totalA:    totalA,
                totalB:    totalB,
                totalTx:   totalTx,
              ),

            SizedBox(height: isMobile ? 16 : 20),

            // ── Section: Riwayat ──────────────────────────────────────────
            _SectionLabel(
              icon:  Icons.history_rounded,
              label: 'Riwayat Data Timbangan',
              color: const Color(0xFF0EA5E9),
            ),
            SizedBox(height: isMobile ? 10 : 12),

            if (isMobile)
              _MobileRecordList(records: ctrl.filteredRecords)
            else
              _AnalyticsHistoryTable(
                records:  ctrl.filteredRecords,
                isMobile: false,
              ),

            SizedBox(height: isMobile ? 16 : 20),

            // ── Section: Chart ────────────────────────────────────────────
            _SectionLabel(
              icon:  Icons.bar_chart_rounded,
              label: 'Visualisasi Produksi',
              color: const Color(0xFF0EA5E9),
            ),
            SizedBox(height: isMobile ? 10 : 12),

            if (isMobile) ...[
              _ChartWithTab(ctrl: ctrl),
              const SizedBox(height: 16),
              _LineRanking(data: linePerf),
            ] else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _ChartWithTab(ctrl: ctrl)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _LineRanking(data: linePerf)),
              ]),

            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }
}

// ── Mobile KPI Cards — Real Weight card DIHAPUS ───────────────────────────────
class _MobileKpiCards extends StatelessWidget {
  final double totalProd, totalA, totalB;
  final int totalTx;
  const _MobileKpiCards({
    required this.totalProd,
    required this.totalA,
    required this.totalB,
    required this.totalTx,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _MiniKCard(
          label: 'Total Produksi',
          value: _wFmt(totalProd),
          icon:  Icons.inventory_2_rounded,
          color: totalProd < 0
              ? const Color(0xFFEE5A24)
              : const Color(0xFF0EA5E9),
        )),
        const SizedBox(width: 10),
        Expanded(child: _MiniKCard(
          label: 'Total Sesi',
          value: '$totalTx sesi',
          icon:  Icons.receipt_long_rounded,
          color: const Color(0xFFF59E0B),
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _MiniKCard(
          label: 'Record A',
          value: _wFmt(totalA),
          icon:  Icons.looks_one_rounded,
          color: totalA < 0
              ? const Color(0xFFEE5A24)
              : const Color(0xFF8B5CF6),
        )),
        const SizedBox(width: 10),
        Expanded(child: _MiniKCard(
          label: 'Record B',
          value: _wFmt(totalB),
          icon:  Icons.looks_two_rounded,
          color: totalB < 0
              ? const Color(0xFFEE5A24)
              : const Color(0xFF10B981),
        )),
      ]),
      // Real Weight full-width card → DIHAPUS
    ]);
  }
}

class _MiniKCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniKCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      );
}

// ── Desktop KPI Cards — cards2 (Real Weight row) DIHAPUS ─────────────────────
class _DesktopKpiCards extends StatelessWidget {
  final double totalProd, totalA, totalB;
  final int totalTx;
  const _DesktopKpiCards({
    required this.totalProd,
    required this.totalA,
    required this.totalB,
    required this.totalTx,
  });

  @override
  Widget build(BuildContext context) {
    final cards1 = [
      _KCardData(
          'Total Produksi', _wFmt(totalProd), 'Record keseluruhan',
          Icons.inventory_2_rounded,
          totalProd < 0
              ? [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)]
              : [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
          totalProd < 0
              ? const Color(0x44EE5A24)
              : const Color(0x440EA5E9)),
      _KCardData(
          'Record A', _wFmt(totalA), 'Total Record A',
          Icons.looks_one_rounded,
          totalA < 0
              ? [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)]
              : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
          totalA < 0
              ? const Color(0x44EE5A24)
              : const Color(0x448B5CF6)),
      _KCardData(
          'Record B', _wFmt(totalB), 'Total Record B',
          Icons.looks_two_rounded,
          totalB < 0
              ? [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
          totalB < 0
              ? const Color(0x44EE5A24)
              : const Color(0x4410B981)),
      _KCardData(
          'Total Sesi', '$totalTx sesi', 'Rekaman selesai',
          Icons.receipt_long_rounded,
          const [Color(0xFFF59E0B), Color(0xFFD97706)],
          const Color(0x44F59E0B)),
    ];

    // cards2 (Real Weight Total, Real A, Real B) → DIHAPUS
    // Hanya tampilkan 1 baris cards1
    return Row(children: [
      for (int i = 0; i < cards1.length; i++) ...[
        Expanded(child: _KCard(data: cards1[i])),
        if (i < cards1.length - 1) const SizedBox(width: 12),
      ],
    ]);
  }
}

class _KCardData {
  final String label, value, sub;
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;
  const _KCardData(this.label, this.value, this.sub, this.icon,
      this.gradient, this.glowColor);
}

class _KCard extends StatelessWidget {
  final _KCardData data;
  const _KCard({required this.data});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
              color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(
                  color: data.glowColor, blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(data.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.value,
                    style: TextStyle(
                        color: data.gradient.last,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(data.label,
                    style: const TextStyle(
                        color: AppColors.textHead,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
                Text(data.sub,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 9.5)),
              ])),
        ]),
      );
}

// ── Mobile Record List ────────────────────────────────────────────────────────
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
    if (widget.records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: AppEmptyView(message: 'Tidak ada data untuk periode ini'),
        ),
      );
    }

    final recs = _pageRecords;
    final totalAll = widget.records.fold(0.0, (s, r) => s + r.recordHistoryAll);

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
          const Icon(Icons.functions_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('${widget.records.length} sesi',
              style: const TextStyle(
                  color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('Total: ${_wFmt(totalAll)}',
              style: const TextStyle(
                  color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ),
      ...recs.asMap().entries.map((e) => _MobileRecordCard(
            record: e.value,
            index: (_page - 1) * _perPage + e.key + 1,
          )),
      if (_totalPages > 1)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _NavBtn2(
                icon: Icons.chevron_left_rounded,
                enabled: _page > 1,
                onTap: () => setState(() => _page--)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$_page / $_totalPages',
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 13, fontWeight: FontWeight.w600)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(7)),
            child: Center(
              child: Text('$index',
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat('dd MMM yyyy').format(r.dbTime),
                style: const TextStyle(
                    color: AppColors.textHead, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(DateFormat('HH:mm').format(r.dbTime),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sourceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: sourceColor.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(color: sourceColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(r.source,
                  style: TextStyle(
                      color: sourceColor, fontSize: 9.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 8),
        Row(children: [
          LineBadge(line: r.line, fontSize: 10),
          const SizedBox(width: 8),
          ShiftBadge(shift: r.shift, fontSize: 10),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _WeightCell('Total Rec', r.recordHistoryAll, AppColors.primary),
          _WeightCell('Rec A', r.recordWeightA, const Color(0xFF8B5CF6)),
          _WeightCell('Rec B', r.recordWeightB, const Color(0xFF10B981)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _WeightCell('Real A', r.realWeightA, const Color(0xFF0891B2)),
          _WeightCell('Real B', r.realWeightB, const Color(0xFF0891B2)),
          _WeightCell('Real Total', r.totalRealWeight, const Color(0xFF0891B2)),
        ]),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
  const _NavBtn2({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primaryLight : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: enabled ? AppColors.primarySoft : AppColors.border),
          ),
          child: Icon(icon,
              size: 20,
              color: enabled ? AppColors.primary : AppColors.textMuted),
        ),
      );
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.textHead, fontSize: 13, fontWeight: FontWeight.w800)),
      ]);
}

// ── Chart With Tab ────────────────────────────────────────────────────────────
class _ChartWithTab extends StatelessWidget {
  final AnalyticsController ctrl;
  const _ChartWithTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Produksi per Line',
              style: TextStyle(
                  color: AppColors.textHead,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          const Spacer(),
          Obx(() => _TabToggle(
                selected: ctrl.chartTab.value,
                onChanged: (i) => ctrl.chartTab.value = i,
              )),
        ]),
        const SizedBox(height: 14),
        Obx(() {
          final isA        = ctrl.chartTab.value == 0;
          final data       = isA ? ctrl.dailyDataA : ctrl.dailyDataB;
          final accentColor = isA
              ? const Color(0xFF8B5CF6)
              : const Color(0xFF10B981);
          return _ProductionChart(data: data, accentColor: accentColor);
        }),
      ]),
    );
  }
}

class _TabToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _TabToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _TabBtn(label: 'Record A', active: selected == 0,
            activeColor: const Color(0xFF8B5CF6), onTap: () => onChanged(0)),
        const SizedBox(width: 3),
        _TabBtn(label: 'Record B', active: selected == 1,
            activeColor: const Color(0xFF10B981), onTap: () => onChanged(1)),
      ]),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active,
      required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

// ── Production Chart (tidak berubah) ─────────────────────────────────────────
class _ProductionChart extends StatefulWidget {
  final List<DailyProduction> data;
  final Color accentColor;
  const _ProductionChart({required this.data, required this.accentColor});

  @override
  State<_ProductionChart> createState() => _ProductionChartState();
}

class _ProductionChartState extends State<_ProductionChart>
    with SingleTickerProviderStateMixin {
  final Set<String> _hiddenLines = {};
  late AnimationController _anim;
  late Animation<double> _grow;
  _TooltipData? _tooltip;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));
    _grow = CurvedAnimation(parent: _anim, curve: Curves.easeOutQuart);
    _anim.forward();
  }

  @override
  void didUpdateWidget(_ProductionChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data || old.accentColor != widget.accentColor) {
      _hiddenLines.clear();
      _tooltip = null;
      _anim.reset();
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (widget.data.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart_rounded,
                color: AppColors.textMuted.withOpacity(0.3), size: 36),
            const SizedBox(height: 8),
            const Text('Belum ada data untuk ditampilkan',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
      );
    }

    final maxShow    = isMobile ? 7 : 14;
    final allDisplay = widget.data.length > maxShow
        ? widget.data.sublist(widget.data.length - maxShow)
        : widget.data;

    final allLines = <String>{};
    for (final d in allDisplay) allLines.addAll(d.perLine.keys);
    final lines = allLines.toList()..sort();

    final effectiveHidden = Set<String>.from(_hiddenLines);
    final activeLines     = lines.where((l) => !effectiveHidden.contains(l)).toList();

    double maxPos = 1.0, maxNeg = 0.0;
    for (final d in allDisplay) {
      for (final l in activeLines) {
        final v = d.perLine[l] ?? 0;
        if (v > maxPos) maxPos = v;
        if (v < -maxNeg) maxNeg = v.abs();
      }
    }

    String yFmt(double v) => v.abs() >= 1000
        ? '${NumberFormat('#,##0.###', 'id_ID').format(v / 1000)}t'
        : _numFmt.format(v);

    const chartH = 180.0;
    const yAxisW = 44.0;
    const labelH = 22.0;
    final plotH      = chartH - labelH;
    final totalRange = maxPos + maxNeg;
    final posH = totalRange > 0 ? plotH * (maxPos / totalRange) : plotH;
    final negH = totalRange > 0 ? plotH * (maxNeg / totalRange) : 0.0;
    final baseY = posH;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (lines.isNotEmpty)
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: lines.map((l) {
            final hidden = effectiveHidden.contains(l);
            final col    = LineColors.of(l);
            return GestureDetector(
              onTap: () => setState(() {
                if (_hiddenLines.contains(l)) {
                  _hiddenLines.remove(l);
                } else {
                  _hiddenLines.add(l);
                }
                _anim.reset();
                _anim.forward();
              }),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: hidden ? 0.35 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hidden ? AppColors.surfaceAlt : col.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: hidden ? AppColors.border : col.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 7, height: 7,
                        decoration: BoxDecoration(
                            color: hidden ? AppColors.textMuted : col,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(l,
                        style: TextStyle(
                            color: hidden ? AppColors.textMuted : col,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),

      const SizedBox(height: 14),

      SizedBox(
        height: chartH,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: yAxisW,
            child: Stack(children: [
              for (final frac in [0.5, 1.0])
                Positioned(
                  top: (baseY - posH * frac) - 6,
                  right: 4,
                  child: Text(yFmt(maxPos * frac),
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w600)),
                ),
              if (maxNeg > 0)
                for (final frac in [0.5, 1.0])
                  Positioned(
                    top: (baseY + negH * frac) - 6,
                    right: 4,
                    child: Text(yFmt(-(maxNeg * frac)),
                        style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 8,
                            fontWeight: FontWeight.w600)),
                  ),
            ]),
          ),
          Expanded(
            child: LayoutBuilder(builder: (ctx, constraints) {
              final chartWidth = constraints.maxWidth;
              final dayCount   = allDisplay.length;
              final groupW     = chartWidth / dayCount;
              final barCount   = activeLines.isEmpty ? 1 : activeLines.length;
              final barPad     = groupW * 0.12;
              const gap        = 1.5;
              final barW = ((groupW - barPad * 2 - gap * (barCount - 1)) / barCount)
                  .clamp(2.0, 22.0);

              return MouseRegion(
                cursor: SystemMouseCursors.precise,
                onExit: (_) => setState(() => _tooltip = null),
                child: Listener(
                  onPointerMove: (e) => _onHover(e.localPosition, allDisplay,
                      activeLines, groupW, barPad, barW, baseY, posH, negH),
                  onPointerHover: (e) => _onHover(e.localPosition, allDisplay,
                      activeLines, groupW, barPad, barW, baseY, posH, negH),
                  child: Stack(children: [
                    AnimatedBuilder(
                      animation: _grow,
                      builder: (_, __) => CustomPaint(
                        size: Size(chartWidth, chartH),
                        painter: _ChartGridPainter(
                          data:         allDisplay,
                          lines:        activeLines,
                          maxPos:       maxPos,
                          maxNeg:       maxNeg,
                          posH:         posH,
                          negH:         negH,
                          baseY:        baseY,
                          growFactor:   _grow.value,
                          labelH:       labelH,
                          isMobile:     isMobile,
                          hoveredLine:  _tooltip?.line,
                          hoveredDate:  _tooltip?.date,
                        ),
                      ),
                    ),
                    if (_tooltip != null)
                      _ChartTooltip(
                          data: _tooltip!,
                          chartWidth:  chartWidth,
                          chartHeight: chartH),
                  ]),
                ),
              );
            }),
          ),
        ]),
      ),
    ]);
  }

  void _onHover(Offset localPos, List<DailyProduction> data, List<String> lines,
      double groupW, double barPad, double barW, double baseY,
      double posH, double negH) {
    const gap = 1.5;
    for (int di = 0; di < data.length; di++) {
      final d      = data[di];
      final groupX = di * groupW;
      for (int li = 0; li < lines.length; li++) {
        final l   = lines[li];
        final val = d.perLine[l] ?? 0;
        if (val == 0) continue;
        final isNeg = val < 0;
        final x     = groupX + barPad + li * (barW + gap);
        final barH  = isNeg ? negH : posH;
        final barTop = isNeg ? baseY : baseY - barH;
        final rect  = Rect.fromLTWH(x, barTop, barW, barH);
        if (rect.contains(localPos)) {
          setState(() {
            _tooltip = _TooltipData(
              line:    l,
              date:    d.date,
              value:   val,
              label:   '${_numFmt.format(val.abs())} kg',
              cursorX: localPos.dx,
              cursorY: localPos.dy,
            );
          });
          return;
        }
      }
    }
    if (_tooltip != null) setState(() => _tooltip = null);
  }
}

class _TooltipData {
  final String line, label;
  final DateTime date;
  final double value, cursorX, cursorY;
  const _TooltipData({required this.line, required this.date, required this.value,
      required this.label, required this.cursorX, required this.cursorY});
}

class _ChartTooltip extends StatelessWidget {
  final _TooltipData data;
  final double chartWidth, chartHeight;
  const _ChartTooltip({required this.data, required this.chartWidth,
      required this.chartHeight});

  @override
  Widget build(BuildContext context) {
    const tipW = 148.0, tipH = 68.0, margin = 8.0;
    double left = data.cursorX + 12;
    double top  = data.cursorY - tipH / 2;
    if (left + tipW > chartWidth - margin) left = data.cursorX - tipW - 12;
    top = top.clamp(margin, chartHeight - tipH - margin);
    final color  = LineColors.of(data.line);
    final isNeg  = data.value < 0;
    final valColor = isNeg ? AppColors.danger : color;

    return Positioned(
      left: left, top: top,
      child: IgnorePointer(
        child: Container(
          width: tipW,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(0.35), width: 1.5),
            boxShadow: [BoxShadow(
                color: color.withOpacity(0.18), blurRadius: 16,
                offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Line ${data.line}',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(DateFormat('dd/MM').format(data.date),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
            ]),
            const SizedBox(height: 7),
            const Divider(height: 1, color: Color(0xFFEEF2FF)),
            const SizedBox(height: 7),
            Text('${data.value < 0 ? "-" : ""}${data.label}',
                style: TextStyle(
                    color: valColor, fontSize: 15, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}

class _ChartGridPainter extends CustomPainter {
  final List<DailyProduction> data;
  final List<String> lines;
  final double maxPos, maxNeg, posH, negH, baseY, growFactor, labelH;
  final bool isMobile;
  final String? hoveredLine;
  final DateTime? hoveredDate;

  const _ChartGridPainter({
    required this.data, required this.lines, required this.maxPos,
    required this.maxNeg, required this.posH, required this.negH,
    required this.baseY, required this.growFactor, required this.labelH,
    required this.isMobile, this.hoveredLine, this.hoveredDate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final w        = size.width;
    final dayCount = data.length;
    final groupW   = w / dayCount;
    final barCount = lines.isEmpty ? 1 : lines.length;
    final barPad   = groupW * 0.12;
    const gap      = 1.5;
    final barW = ((groupW - barPad * 2 - gap * (barCount - 1)) / barCount)
        .clamp(2.0, 22.0);

    final gridPaint = Paint()..color = const Color(0xFFE8EDF5)..strokeWidth = 1;
    for (final frac in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawLine(Offset(0, baseY - posH * frac),
          Offset(w, baseY - posH * frac), gridPaint);
    }
    if (maxNeg > 0) {
      for (final frac in [0.5, 1.0]) {
        canvas.drawLine(Offset(0, baseY + negH * frac),
            Offset(w, baseY + negH * frac),
            Paint()
              ..color = AppColors.danger.withOpacity(0.12)
              ..strokeWidth = 1);
      }
    }
    canvas.drawLine(Offset(0, baseY), Offset(w, baseY),
        Paint()..color = const Color(0xFFC8D0E0)..strokeWidth = 1.5);

    for (int di = 0; di < data.length; di++) {
      final d      = data[di];
      final groupX = di * groupW;

      for (int li = 0; li < lines.length; li++) {
        final l   = lines[li];
        final val = d.perLine[l] ?? 0;
        if (val == 0) continue;
        final isNeg  = val < 0;
        final ratio  = isNeg
            ? (maxNeg > 0 ? val.abs() / maxNeg : 0.0)
            : (maxPos > 0 ? val / maxPos : 0.0);
        final barH = ((isNeg ? negH : posH) * ratio * growFactor)
            .clamp(0.0, isNeg ? negH : posH);
        if (barH < 0.5) continue;

        final x          = groupX + barPad + li * (barW + gap);
        final y          = isNeg ? baseY : baseY - barH;
        final baseColor  = isNeg ? AppColors.danger : LineColors.of(l);
        final isHovered  = hoveredLine == l && hoveredDate != null &&
            hoveredDate!.year  == d.date.year &&
            hoveredDate!.month == d.date.month &&
            hoveredDate!.day   == d.date.day;
        final hasAnyHover = hoveredLine != null;
        final opacity    = hasAnyHover ? (isHovered ? 1.0 : 0.3) : 1.0;
        final color      = baseColor.withOpacity(opacity);

        final rect = Rect.fromLTWH(x, y, barW, barH);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..shader = LinearGradient(
              begin: isNeg ? Alignment.topCenter : Alignment.bottomCenter,
              end:   isNeg ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [color, color.withOpacity(0.55 * opacity)],
            ).createShader(rect),
        );
        canvas.drawLine(
          Offset(x + 1.5, isNeg ? y + barH : y),
          Offset(x + barW - 1.5, isNeg ? y + barH : y),
          Paint()..color = color..strokeWidth = isHovered ? 2.5 : 2,
        );
      }

      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center, fontSize: isMobile ? 7.5 : 8.5))
        ..pushStyle(ui.TextStyle(
            color: const Color(0xFF94A3B8), fontWeight: ui.FontWeight.w600))
        ..addText(DateFormat('dd/MM').format(d.date));
      final para = pb.build()..layout(ui.ParagraphConstraints(width: groupW));
      canvas.drawParagraph(para, Offset(groupX, baseY + negH + 4));
    }
  }

  @override
  bool shouldRepaint(_ChartGridPainter old) =>
      old.growFactor != growFactor || old.data != data || old.lines != lines ||
      old.hoveredLine != hoveredLine || old.hoveredDate != hoveredDate;
}

// ── Line Ranking ──────────────────────────────────────────────────────────────
class _LineRanking extends StatelessWidget {
  final List<LinePerformance> data;
  const _LineRanking({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty
        ? 1.0
        : data.map((d) => d.totalWeight.abs()).reduce((a, b) => a > b ? a : b);
    const medals = ['🥇', '🥈', '🥉'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFFDE68A))),
            child: const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFF59E0B), size: 16),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ranking Line',
                style: TextStyle(
                    color: AppColors.textHead,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            Text('Berdasarkan total produksi',
                style: TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
          ]),
        ]),
        const SizedBox(height: 18),

        if (data.isEmpty)
          const SizedBox(
            height: 80,
            child: Center(child: Text('Belum ada data ranking',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          )
        else
          ...data.asMap().entries.map((e) {
            final i      = e.key;
            final d      = e.value;
            final ratio  = maxVal > 0 ? d.totalWeight.abs() / maxVal : 0.0;
            final medal  = i < medals.length ? medals[i] : '${i + 1}.';
            final color  = LineColors.of(d.line);
            final isNeg  = d.totalWeight < 0;
            final barCol = isNeg ? AppColors.danger : color;
            final weightStr = isNeg
                ? '-${_numFmt.format(d.totalWeight.abs())} kg'
                : d.totalWeight.abs() >= 1000
                    ? '${NumberFormat('#,##0.###', 'id_ID').format(d.totalWeight / 1000)} t'
                    : '${_numFmt.format(d.totalWeight)} kg';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(medal, style: const TextStyle(fontSize: 14, height: 1)),
                  const SizedBox(width: 9),
                  LineBadge(line: d.line, fontSize: 10),
                  const Spacer(),
                  Text(weightStr,
                      style: TextStyle(
                          color: barCol, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 7),
                Stack(children: [
                  Container(height: 7,
                      decoration: BoxDecoration(
                          color: barCol.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: Container(height: 7,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [barCol.withOpacity(0.7), barCol]),
                            borderRadius: BorderRadius.circular(4))),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${d.totalTransactions} sesi timbang',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 9)),
              ]),
            );
          }),
      ]),
    );
  }
}

// ── Desktop Analytics History Table ──────────────────────────────────────────
class _AnalyticsHistoryTable extends StatefulWidget {
  final List<WeightRecord> records;
  final bool isMobile;
  const _AnalyticsHistoryTable(
      {required this.records, required this.isMobile});

  @override
  State<_AnalyticsHistoryTable> createState() => _AnalyticsHistoryTableState();
}

class _AnalyticsHistoryTableState extends State<_AnalyticsHistoryTable> {
  int _page        = 1;
  int _rowsPerPage = AppConstants.defaultRowsPerPage;

  int get _totalPages => widget.records.isEmpty
      ? 1
      : (widget.records.length / _rowsPerPage).ceil().clamp(1, 99999);

  List<WeightRecord> get _pageRecords {
    if (widget.records.isEmpty) return [];
    final start = (_page - 1) * _rowsPerPage;
    final end   = (start + _rowsPerPage).clamp(0, widget.records.length);
    return widget.records.sublist(start, end);
  }

  @override
  void didUpdateWidget(_AnalyticsHistoryTable old) {
    super.didUpdateWidget(old);
    if (old.records != widget.records) setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) {
    final pageRecs   = _pageRecords;
    const double rowH = 56.0;
    const double maxVisibleRows = 10;
    final double scrollH = pageRecs.isEmpty
        ? rowH * 3
        : (pageRecs.length.clamp(1, maxVisibleRows.toInt()) * rowH);

    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const _AHTableHeader(),
            SizedBox(
              height: scrollH,
              child: pageRecs.isEmpty
                  ? const Center(
                      child: Text('Tidak ada data',
                          style: TextStyle(color: AppColors.textMuted)))
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        itemCount: pageRecs.length,
                        itemBuilder: (_, i) => _AHTRow(
                          record:  pageRecs[i],
                          index:   (_page - 1) * _rowsPerPage + i + 1,
                          isEven:  i.isEven,
                        ),
                      ),
                    ),
            ),
            _SubtotalFooter(records: pageRecs),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Row(children: [
          Text(
            widget.records.isEmpty
                ? '0 data'
                : '${(_page - 1) * _rowsPerPage + 1}–'
                    '${(_page * _rowsPerPage).clamp(1, widget.records.length)} '
                    'dari ${widget.records.length}',
            style: const TextStyle(color: AppColors.textSub, fontSize: 12),
          ),
          const Spacer(),
          _NavBtn2(
              icon:    Icons.chevron_left_rounded,
              enabled: _page > 1,
              onTap:   () => setState(() => _page--)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$_page / $_totalPages',
                style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
          ),
          _NavBtn2(
              icon:    Icons.chevron_right_rounded,
              enabled: _page < _totalPages,
              onTap:   () => setState(() => _page++)),
        ]),
      ),
    ]);
  }
}

const double _wNo = 40, _wLine = 68, _wShift = 80, _wSource = 72, _kHPad = 20;

class _AHTableHeader extends StatelessWidget {
  const _AHTableHeader();

  static const _hs = TextStyle(
      color: AppColors.textSub, fontSize: 10,
      fontWeight: FontWeight.w700, letterSpacing: 0.6);
  static const _realHs = TextStyle(
      color: Color(0xFF06B6D4), fontSize: 10,
      fontWeight: FontWeight.w700, letterSpacing: 0.6);

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F9FF),
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _kHPad, vertical: 11),
        child: Row(children: [
          SizedBox(width: _wNo, child: const Text('NO', textAlign: TextAlign.center, style: _hs)),
          const SizedBox(width: 12),
          const Expanded(flex: 3, child: Text('TANGGAL / WAKTU', style: _hs)),
          const SizedBox(width: 12),
          SizedBox(width: _wLine,   child: const Text('LINE',   textAlign: TextAlign.center, style: _hs)),
          const SizedBox(width: 10),
          SizedBox(width: _wShift,  child: const Text('SHIFT',  textAlign: TextAlign.center, style: _hs)),
          const SizedBox(width: 10),
          SizedBox(width: _wSource, child: const Text('SUMBER', textAlign: TextAlign.center, style: _hs)),
          const SizedBox(width: 10),
          const Expanded(flex: 2, child: Text('TOTAL REC', textAlign: TextAlign.right, style: _hs)),
          const Expanded(flex: 2, child: Text('REC A',     textAlign: TextAlign.right, style: _hs)),
          const Expanded(flex: 2, child: Text('REC B',     textAlign: TextAlign.right, style: _hs)),
          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: AppColors.border),
          const SizedBox(width: 8),
          const Expanded(flex: 2, child: Text('REAL A',     textAlign: TextAlign.right, style: _realHs)),
          const Expanded(flex: 2, child: Text('REAL B',     textAlign: TextAlign.right, style: _realHs)),
          const Expanded(flex: 2, child: Text('REAL TOTAL', textAlign: TextAlign.right, style: _realHs)),
        ]),
      );
}

class _AHTRow extends StatefulWidget {
  final WeightRecord record;
  final int index;
  final bool isEven;
  const _AHTRow({required this.record, required this.index, required this.isEven});

  @override
  State<_AHTRow> createState() => _AHTRowState();
}

class _AHTRowState extends State<_AHTRow> {
  bool _hovered = false;

  Widget _num(double val, int flex) => Expanded(
        flex: flex,
        child: Text(_numFmt.format(val),
            textAlign: TextAlign.right,
            style: TextStyle(
                color: val < 0 ? AppColors.danger : AppColors.textBody,
                fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _realNum(double val, int flex) => Expanded(
        flex: flex,
        child: Text(_numFmt.format(val),
            textAlign: TextAlign.right,
            style: TextStyle(
                color: val < 0 ? AppColors.danger : const Color(0xFF0891B2),
                fontSize: 12, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final r           = widget.record;
    final isAuto      = r.source == 'Auto';
    final sourceColor = isAuto ? const Color(0xFF0EA5E9) : const Color(0xFF8B5CF6);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFFF0F9FF)
              : widget.isEven ? AppColors.surface : AppColors.surfaceAlt,
          border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _kHPad, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: _wNo,
            child: Center(child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: _hovered ? AppColors.primarySoft : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(7)),
              child: Center(child: Text('${widget.index}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800))),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.primarySoft, width: 0.8)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(DateFormat('dd').format(r.dbTime),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                  Text(DateFormat('MMM').format(r.dbTime).toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.textSub,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(width: 9),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('dd-MM-yyyy').format(r.dbTime),
                    style: const TextStyle(
                        color: AppColors.textHead,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.schedule_rounded,
                      size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(DateFormat('HH:mm').format(r.dbTime),
                      style: const TextStyle(
                          color: AppColors.textSub, fontSize: 11)),
                ]),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          SizedBox(width: _wLine,
              child: Center(child: LineBadge(line: r.line))),
          const SizedBox(width: 10),
          SizedBox(width: _wShift,
              child: Center(child: ShiftBadge(shift: r.shift))),
          const SizedBox(width: 10),
          SizedBox(
            width: _wSource,
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: sourceColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sourceColor.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(
                        color: sourceColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(r.source,
                    style: TextStyle(
                        color: sourceColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ]),
            )),
          ),
          const SizedBox(width: 10),
          _num(r.recordHistoryAll, 2),
          _num(r.recordWeightA,    2),
          _num(r.recordWeightB,    2),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: AppColors.border),
          const SizedBox(width: 8),
          _realNum(r.realWeightA,    2),
          _realNum(r.realWeightB,    2),
          _realNum(r.totalRealWeight, 2),
        ]),
      ),
    );
  }
}

class _SubtotalFooter extends StatelessWidget {
  final List<WeightRecord> records;
  const _SubtotalFooter({required this.records});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _kHPad, vertical: 10),
      child: Row(children: [
        const Icon(Icons.functions_rounded, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        const Text('Subtotal halaman ini',
            style: TextStyle(
                color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

  Widget _chip(String val, String label, Color col, {bool large = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: col.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: col.withOpacity(0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(val,
              style: TextStyle(
                  color: col,
                  fontSize: large ? 13 : 11,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: col.withOpacity(0.65),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600)),
        ]),
      );
