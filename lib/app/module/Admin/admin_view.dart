import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timbangan_spd/app/core/theme/app_colors.dart';
import 'package:timbangan_spd/app/module/Admin/admin_controller.dart';
import 'package:timbangan_spd/app/routes/menus_tab.dart';
import 'package:timbangan_spd/app/service/activity_log_tab.dart';
import 'package:timbangan_spd/app/service/users_tab.dart';
import 'package:timbangan_spd/sidebar.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminController>();

    return ResponsiveScaffold(
      title: 'Admin Panel',
      child: Column(children: [
        _AdminTopBar(ctrl: ctrl),
        Expanded(
          child: Obx(() => switch (ctrl.selectedTab.value) {
                0 => UsersTab(ctrl: ctrl),
                1 => MenusTab(ctrl: ctrl),
                2 => ActivityLogTab(ctrl: ctrl),
                _ => UsersTab(ctrl: ctrl),
              }),
        ),
      ]),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _AdminTopBar extends StatelessWidget {
  final AdminController ctrl;
  const _AdminTopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F5), width: 1)),
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.admin_panel_settings_rounded,
              size: 17, color: Color(0xFF4F69F5)),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23))),
            Text('Programmer only',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ],
        ),
        const SizedBox(width: 20),

        // Tabs
        Obx(() => Row(
              children: [
                _Tab(
                  label: 'Users',
                  icon: Icons.people_outline_rounded,
                  active: ctrl.selectedTab.value == 0,
                  onTap: () => ctrl.selectedTab.value = 0,
                ),
                const SizedBox(width: 4),
                _Tab(
                  label: 'Menu Akses',
                  icon: Icons.grid_view_rounded,
                  active: ctrl.selectedTab.value == 1,
                  onTap: () => ctrl.selectedTab.value = 1,
                ),
                const SizedBox(width: 4),
                _Tab(
                  label: 'Activity Log',
                  icon: Icons.history_rounded,
                  active: ctrl.selectedTab.value == 2,
                  onTap: () {
                    ctrl.selectedTab.value = 2;
                    ctrl.fetchLogs();
                  },
                ),
              ],
            )),

        const Spacer(),

        // Refresh
        GestureDetector(
          onTap: () {
            ctrl.fetchUsers();
            ctrl.fetchMenus();
          },
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF6B7280)),
                SizedBox(width: 5),
                Text('Refresh',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Tab(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4F69F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: active ? Colors.white : const Color(0xFF9CA3AF)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}