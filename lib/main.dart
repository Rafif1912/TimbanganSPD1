import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timbangan_spd/app/module/Login/controller/login_controller.dart';
import 'package:timbangan_spd/app/routes/app_pages.dart';
import 'package:timbangan_spd/app/routes/app_routes.dart';
import 'package:timbangan_spd/app/service/auth_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  runApp(const SpdTimbangan());
}

class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class SpdTimbangan extends StatelessWidget {
  const SpdTimbangan({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SPD Timbangan',
      theme: _buildTheme(),
      scrollBehavior: _WebScrollBehavior(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      getPages: AppPages.routes,
      routingCallback: (routing) {
        final route = routing?.current ?? '';
        if (route == AppRoutes.login) return;
        if (!Get.isRegistered<LoginController>()) {
          Get.put(LoginController(), permanent: true);
        }
      },
      unknownRoute: GetPage(
        name: AppRoutes.login,
        page: () => _Redirector(to: AppRoutes.login),
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(LoginController(), permanent: true);
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Auth Middleware
// ─────────────────────────────────────────────
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (route == AppRoutes.login) return null;

    final token = AuthStorageService.getAccessToken();
    if (token == null || token.isEmpty) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

class _Redirector extends StatelessWidget {
  final String to;
  const _Redirector({required this.to});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.offAllNamed(to));
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ─────────────────────────────────────────────
// App Theme
// ─────────────────────────────────────────────
ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F7FF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6C8EF5),
      secondary: Color(0xFF9B6CF5),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFEF5350),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1E2A4A)),
      bodyMedium: TextStyle(color: Color(0xFF3D4E7A)),
      bodySmall: TextStyle(color: Color(0xFF9BA8C7)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C8EF5),
        foregroundColor: Colors.white,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E2A4A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}