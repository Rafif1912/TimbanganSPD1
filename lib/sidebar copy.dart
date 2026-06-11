import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timbangan_spd/app/core/theme/app_colors.dart';
import 'package:timbangan_spd/app/module/Login/controller/login_controller.dart';
import 'package:timbangan_spd/app/routes/app_routes.dart';
import 'package:timbangan_spd/app/widget/running_text.dart';

// ─────────────────────────────────────────────
// Responsive Scaffold
// ─────────────────────────────────────────────
class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  const ResponsiveScaffold(
      {super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;
    final location = Get.currentRoute;

    final navItems = [
      _NavDef(Icons.dashboard_rounded, 'Dashboard', AppRoutes.dashboard),
      _NavDef(Icons.bar_chart_rounded, 'Analitik', AppRoutes.analytics),
      _NavDef(Icons.history_rounded, 'Riwayat', AppRoutes.history),
      _NavDef(Icons.settings_rounded, 'Pengaturan', AppRoutes.settings),
    ];

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF4F6EF7), Color(0xFF7B52F5)]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.scale, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    color: AppColors.textHead,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.danger, size: 20),
              onPressed: () => Get.find<LoginController>().logout(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border),
          ),
        ),
        body: Column(children: [
          const RunningText(),
          Expanded(child: child),
        ]),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: navItems.map((item) {
                  final active = location == item.route;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => Get.toNamed(item.route),
                      behavior: HitTestBehavior.opaque,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(item.icon,
                            color: active
                                ? AppColors.primary
                                : AppColors.textMuted,
                            size: 24),
                        const SizedBox(height: 3),
                        Text(item.label,
                            style: TextStyle(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    }

    // Desktop
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const RunningText(),
        Expanded(
          child: Row(children: [
            _DesktopSidebar(compact: w < 1000),
            Expanded(child: child),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// Nav Definition
// ─────────────────────────────────────────────
class _NavDef {
  final IconData icon;
  final String label;
  final String route;
  const _NavDef(this.icon, this.label, this.route);
}

// ─────────────────────────────────────────────
// Desktop Sidebar
// ─────────────────────────────────────────────
class _DesktopSidebar extends StatelessWidget {
  final bool compact;
  const _DesktopSidebar({required this.compact});

  @override
  Widget build(BuildContext context) {
    final location = Get.currentRoute;
    final loginCtrl = Get.find<LoginController>();
    final w = compact ? 72.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: w,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 12, offset: Offset(2, 0)),
        ],
      ),
      child: Column(children: [
        // Logo
        Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 18),
          child: compact
              ? Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF4F6EF7), Color(0xFF7B52F5)]),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child:
                        const Icon(Icons.scale, color: Colors.white, size: 20),
                  ),
                )
              : Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF4F6EF7), Color(0xFF7B52F5)]),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child:
                        const Icon(Icons.scale, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SPD',
                          style: TextStyle(
                              color: AppColors.textHead,
                              fontWeight: FontWeight.w900,
                              fontSize: 17)),
                      Text('Timbangan',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ]),
        ),

        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 10),

        for (final item in [
          _NavDef(Icons.dashboard_rounded, 'Dashboard', AppRoutes.dashboard),
          _NavDef(Icons.bar_chart_rounded, 'Analitik', AppRoutes.analytics),
          _NavDef(Icons.history_rounded, 'Riwayat', AppRoutes.history),
          _NavDef(Icons.settings_rounded, 'Pengaturan', AppRoutes.settings),
        ])
          _SidebarItem(
              item: item, isActive: location == item.route, compact: compact),

        const Spacer(),
        Container(height: 1, color: AppColors.border),

        // User info
        if (!compact)
          Obx(() => Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (loginCtrl.loggedInUser.value ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loginCtrl.loggedInUser.value ?? 'User',
                              style: const TextStyle(
                                  color: AppColors.textHead,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                          const Text('Operator',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                        ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.danger, size: 16),
                    tooltip: 'Logout',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: loginCtrl.logout,
                  ),
                ]),
              ))
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.danger, size: 18),
              onPressed: () => Get.find<LoginController>().logout(),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// Sidebar Item
// ─────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final _NavDef item;
  final bool isActive;
  final bool compact;
  const _SidebarItem(
      {required this.item, required this.isActive, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Tooltip(
        message: compact ? item.label : '',
        child: InkWell(
          onTap: () => Get.toNamed(item.route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive ? AppColors.primaryLight : Colors.transparent,
            ),
            child: compact
                ? Center(
                    child: Icon(item.icon,
                        color:
                            isActive ? AppColors.primary : AppColors.textMuted,
                        size: 22))
                : Row(children: [
                    Icon(item.icon,
                        color:
                            isActive ? AppColors.primary : AppColors.textMuted,
                        size: 20),
                    const SizedBox(width: 12),
                    Text(item.label,
                        style: TextStyle(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textSub,
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500)),
                    if (isActive) ...[
                      const Spacer(),
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle)),
                    ]
                  ]),
          ),
        ),
      ),
    );
  }
}
