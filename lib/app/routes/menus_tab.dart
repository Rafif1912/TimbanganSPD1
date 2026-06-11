import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timbangan_spd/app/models/auth_models.dart';
import 'package:timbangan_spd/app/module/Admin/admin_controller.dart';
import 'package:timbangan_spd/app/widget/app_widget.dart';

class MenusTab extends StatelessWidget {
  final AdminController ctrl;
  const MenusTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingMenus.value) return const AppLoadingView();
      if (ctrl.menuError.value != null) {
        return AppEmptyView(message: 'Error: ${ctrl.menuError.value}');
      }
      if (ctrl.menus.isEmpty) {
        return const AppEmptyView(message: 'Belum ada data menu');
      }

      return Column(children: [
        // Info bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                size: 14, color: Color(0xFF4F69F5)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Klik chip role untuk mengubah akses menu. Perubahan langsung disimpan.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFEEF0F5)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                childAspectRatio: 1.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: ctrl.menus.length,
              itemBuilder: (_, i) =>
                  _MenuCard(menu: ctrl.menus[i], ctrl: ctrl),
            ),
          ),
        ),
      ]);
    });
  }
}

// ── Menu Card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatefulWidget {
  final MenuModel menu;
  final AdminController ctrl;
  const _MenuCard({required this.menu, required this.ctrl});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _hovered = false;

  IconData _icon(String? name) => switch (name) {
        'dashboard'      => Icons.dashboard_outlined,
        'bar_chart'      => Icons.bar_chart_rounded,
        'history'        => Icons.history_rounded,
        'settings'       => Icons.settings_outlined,
        'people'         => Icons.people_outline_rounded,
        'manage_history' => Icons.manage_history_rounded,
        _                => Icons.web_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final m = widget.menu;
    final hasAdmin = m.roles.contains('Administrator');
    final hasProg  = m.roles.contains('Programmer');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF8F9FC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _hovered
                  ? const Color(0xFFD4DCFF)
                  : const Color(0xFFEEF0F5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.06 : 0.02),
                blurRadius: _hovered ? 12 : 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon(m.icon),
                    size: 16, color: const Color(0xFF4F69F5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.namaMenu,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23))),
                    Text(m.path,
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFFADB5BD))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('#${m.urutan}',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF))),
              ),
            ]),
            const Spacer(),
            const Text('AKSES',
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFADB5BD),
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(children: [
              _RoleChip(
                label: 'Admin',
                active: hasAdmin,
                color: const Color(0xFF6D28D9),
                onTap: () {
                  final r = [...m.roles];
                  hasAdmin ? r.remove('Administrator') : r.add('Administrator');
                  widget.ctrl.updateMenuRoles(m.id, r);
                },
              ),
              const SizedBox(width: 6),
              _RoleChip(
                label: 'Programmer',
                active: hasProg,
                color: const Color(0xFF0369A1),
                onTap: () {
                  final r = [...m.roles];
                  hasProg ? r.remove('Programmer') : r.add('Programmer');
                  widget.ctrl.updateMenuRoles(m.id, r);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _RoleChip(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? color : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.check_rounded : Icons.close_rounded,
              size: 10,
              color: active ? Colors.white : const Color(0xFFADB5BD),
            ),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color:
                        active ? Colors.white : const Color(0xFFADB5BD))),
          ],
        ),
      ),
    );
  }
}