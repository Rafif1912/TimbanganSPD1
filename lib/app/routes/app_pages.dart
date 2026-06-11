import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timbangan_spd/app/module/Admin/admin_controller.dart';
import 'package:timbangan_spd/app/module/Admin/admin_view.dart';
import 'package:timbangan_spd/app/module/Analytics/controller/analytics_controller.dart';
import 'package:timbangan_spd/app/module/Analytics/view/analytics_view.dart';
import 'package:timbangan_spd/app/module/Dashboard/controller/dashboard_controller.dart';
import 'package:timbangan_spd/app/module/Dashboard/view/dashboard_view.dart';
import 'package:timbangan_spd/app/module/History/controller/history_controller.dart';
import 'package:timbangan_spd/app/module/History/view/history_view.dart';
import 'package:timbangan_spd/app/module/Login/controller/login_controller.dart';
import 'package:timbangan_spd/app/module/Login/view/login_view.dart';
import 'package:timbangan_spd/app/routes/app_routes.dart';
import 'package:timbangan_spd/app/wrappers/auto_logout_wrapper.dart';
import 'package:timbangan_spd/main.dart';
import 'package:timbangan_spd/sidebar.dart';

class AppPages {
  AppPages._();

  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LoginController>(() => LoginController());
      }),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => AutoLogoutWrapper(child: const DashboardView()),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<DashboardController>(() => DashboardController());
      }),
    ),
    GetPage(
      name: AppRoutes.analytics,
      page: () => AutoLogoutWrapper(child: const AnalyticsView()),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<AnalyticsController>(() => AnalyticsController());
      }),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => AutoLogoutWrapper(child: const HistoryView()),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<HistoryController>(() => HistoryController());
      }),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => AutoLogoutWrapper(
        child: ResponsiveScaffold(
          title: 'Pengaturan',
          child: const _ComingSoon(
              icon: Icons.settings_rounded, label: 'Pengaturan'),
        ),
      ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => AutoLogoutWrapper(child: const AdminView()),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<AdminController>(() => AdminController());
      }),
    ),
  ];
}

class _ComingSoon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ComingSoon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: const Color(0xFFB0BAD4)),
        const SizedBox(height: 16),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF1E2A4A),
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Fitur akan segera hadir',
            style: TextStyle(color: Color(0xFF9BA8C7), fontSize: 14)),
      ]),
    );
  }
}