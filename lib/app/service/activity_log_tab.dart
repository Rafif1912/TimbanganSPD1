import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timbangan_spd/app/models/auth_models.dart';
import 'package:timbangan_spd/app/module/Admin/admin_controller.dart';
import 'package:timbangan_spd/app/widget/app_widget.dart';

class ActivityLogTab extends StatefulWidget {
  final AdminController ctrl;
  const ActivityLogTab({super.key, required this.ctrl});

  @override
  State<ActivityLogTab> createState() => _ActivityLogTabState();
}

class _ActivityLogTabState extends State<ActivityLogTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.ctrl.fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return Column(children: [
      _FilterBar(ctrl: ctrl),
      Expanded(
        child: Obx(() {
          if (ctrl.isLoadingLogs.value) return const AppLoadingView();
          if (ctrl.logError.value != null) {
            return AppEmptyView(
                message: 'Error: ${ctrl.logError.value}');
          }
          if (ctrl.logs.isEmpty) {
            return const AppEmptyView(
                message: 'Tidak ada log untuk filter ini');
          }
          return _LogTable(logs: ctrl.logs);
        }),
      ),
    ]);
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final AdminController ctrl;
  const _FilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(children: [
        // Count
        Obx(() => Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4DCFF)),
              ),
              child: Row(children: [
                const Icon(Icons.list_alt_rounded,
                    size: 13, color: Color(0xFF4F69F5)),
                const SizedBox(width: 5),
                Text('${ctrl.logs.length} log',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F69F5))),
              ]),
            )),
        const SizedBox(width: 10),

        // Date from
        Obx(() => _DateBtn(
              label: 'Dari',
              value: ctrl.logStartDate.value,
              onPicked: (d) {
                ctrl.logStartDate.value = d;
                ctrl.fetchLogs();
              },
            )),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded,
              size: 13, color: Color(0xFFADB5BD)),
        ),
        Obx(() => _DateBtn(
              label: 'Sampai',
              value: ctrl.logEndDate.value,
              onPicked: (d) {
                ctrl.logEndDate.value = d;
                ctrl.fetchLogs();
              },
            )),
        const SizedBox(width: 10),

        // User filter
        Obx(() {
          final sel = ctrl.logFilterUser.value;
          final name = sel != null
              ? ctrl.users
                      .firstWhereOrNull((u) => u.id == sel)
                      ?.nama ??
                  'User #$sel'
              : null;
          return PopupMenuButton<int?>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            color: Colors.white,
            elevation: 8,
            onSelected: (id) {
              ctrl.logFilterUser.value = id;
              ctrl.fetchLogs();
            },
            itemBuilder: (_) => [
              const PopupMenuItem<int?>(
                value: null,
                child: Text('Semua User',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280))),
              ),
              const PopupMenuDivider(),
              ...ctrl.users.map((u) => PopupMenuItem<int?>(
                    value: u.id,
                    child: Text('${u.nama} (@${u.username})',
                        style: TextStyle(
                            fontSize: 13,
                            color: u.id == sel
                                ? const Color(0xFF4F69F5)
                                : const Color(0xFF374151),
                            fontWeight: u.id == sel
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  )),
            ],
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: sel != null
                    ? const Color(0xFFF0F4FF)
                    : const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: sel != null
                        ? const Color(0xFFD4DCFF)
                        : const Color(0xFFE5E7EB)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_search_outlined,
                    size: 13,
                    color: sel != null
                        ? const Color(0xFF4F69F5)
                        : const Color(0xFFADB5BD)),
                const SizedBox(width: 5),
                Text(name ?? 'Filter User',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel != null
                            ? const Color(0xFF4F69F5)
                            : const Color(0xFFADB5BD))),
                const SizedBox(width: 3),
                Icon(Icons.expand_more_rounded,
                    size: 13,
                    color: sel != null
                        ? const Color(0xFF4F69F5)
                        : const Color(0xFFADB5BD)),
              ]),
            ),
          );
        }),
        const SizedBox(width: 8),

        // Refresh
        GestureDetector(
          onTap: ctrl.fetchLogs,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F69F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [
              Icon(Icons.refresh_rounded, size: 13, color: Colors.white),
              SizedBox(width: 5),
              Text('Tampilkan',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  const _DateBtn(
      {required this.label, required this.value, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: Color(0xFF4F69F5),
                    onPrimary: Colors.white)),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        height: 36,
        constraints: const BoxConstraints(minWidth: 110),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 12, color: Color(0xFF4F69F5)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFADB5BD))),
                Text(
                  value != null
                      ? DateFormat('dd MMM yy').format(value!)
                      : '—',
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Log Table ─────────────────────────────────────────────────────────────────
class _LogTable extends StatelessWidget {
  final List<ActivityLogModel> logs;
  const _LogTable({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEF0F5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(children: [
            // Header
            Container(
              color: const Color(0xFFF8F9FC),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: const Row(children: [
                SizedBox(width: 32, child: _H('NO')),
                SizedBox(width: 10),
                SizedBox(width: 140, child: _H('USER')),
                SizedBox(width: 10),
                SizedBox(width: 110, child: _H('ACTION')),
                SizedBox(width: 10),
                SizedBox(width: 120, child: _H('IP ADDRESS')),
                SizedBox(width: 10),
                Expanded(child: _H('BROWSER')),
                SizedBox(width: 10),
                SizedBox(width: 140, child: _H('WAKTU', right: true)),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFEEF0F5)),
            Expanded(
              child: ListView.separated(
                physics: const ClampingScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFEEF0F5)),
                itemBuilder: (_, i) =>
                    _LogRow(log: logs[i], index: i + 1, isEven: i.isEven),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String text;
  final bool right;
  const _H(this.text, {this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: right ? TextAlign.right : TextAlign.start,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.4));
  }
}

// ── Log Row ───────────────────────────────────────────────────────────────────
class _LogRow extends StatefulWidget {
  final ActivityLogModel log;
  final int index;
  final bool isEven;
  const _LogRow(
      {required this.log, required this.index, required this.isEven});

  @override
  State<_LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<_LogRow> {
  bool _hovered = false;

  Color _ac(String a) => switch (a) {
        'LOGIN'         => const Color(0xFF059669),
        'LOGOUT'        => const Color(0xFF6B7280),
        'TOKEN_REFRESH' => const Color(0xFF0369A1),
        _               => const Color(0xFF7C3AED),
      };

  IconData _ai(String a) => switch (a) {
        'LOGIN'         => Icons.login_rounded,
        'LOGOUT'        => Icons.logout_rounded,
        'TOKEN_REFRESH' => Icons.refresh_rounded,
        _               => Icons.bolt_rounded,
      };

  String _browser(String? ua) {
    if (ua == null || ua.isEmpty) return '-';
    if (ua.contains('Edg/') || ua.contains('Edge/')) {
      final m = RegExp(r'Edg(?:e)?/([\d]+)').firstMatch(ua);
      return 'Edge ${m?.group(1) ?? ''}';
    }
    if (ua.contains('Chrome/')) {
      final m = RegExp(r'Chrome/([\d]+)').firstMatch(ua);
      return 'Chrome ${m?.group(1) ?? ''}';
    }
    if (ua.contains('Firefox/')) return 'Firefox';
    if (ua.contains('Safari/')) return 'Safari';
    return 'Browser lain';
  }

  String _os(String? ua) {
    if (ua == null) return '';
    if (ua.contains('Windows NT 10.0')) return 'Windows 10/11';
    if (ua.contains('Windows NT'))      return 'Windows';
    if (ua.contains('Mac OS X'))        return 'macOS';
    if (ua.contains('Android'))         return 'Android';
    if (ua.contains('iPhone'))          return 'iOS';
    if (ua.contains('Linux'))           return 'Linux';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l  = widget.log;
    final ac = _ac(l.action);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered
            ? const Color(0xFFF8F9FC)
            : widget.isEven
                ? Colors.white
                : const Color(0xFFFAFAFC),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          // No
          SizedBox(
            width: 32,
            child: Text('${widget.index}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFADB5BD))),
          ),
          const SizedBox(width: 10),

          // User
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.namaUser ?? '-',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D23)),
                    overflow: TextOverflow.ellipsis),
                Text('@${l.usernameUser ?? '-'}',
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFFADB5BD)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action
          SizedBox(
            width: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: ac.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_ai(l.action), size: 11, color: ac),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(l.action,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ac),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 10),

          // IP
          SizedBox(
            width: 120,
            child: Text(l.ipAddress ?? '-',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                    fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),

          // Browser + OS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_browser(l.userAgent),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF374151)),
                    overflow: TextOverflow.ellipsis),
                if (_os(l.userAgent).isNotEmpty)
                  Text(_os(l.userAgent),
                      style: const TextStyle(
                          fontSize: 10.5, color: Color(0xFFADB5BD)),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Waktu
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('dd MMM yyyy').format(l.createdAt),
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                Text(DateFormat('HH:mm:ss').format(l.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFADB5BD))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}