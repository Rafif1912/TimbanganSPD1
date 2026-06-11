// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timbangan_spd/app/core/theme/app_colors.dart';
import 'package:timbangan_spd/app/models/scale_model.dart';
import 'package:timbangan_spd/app/module/Dashboard/controller/dashboard_controller.dart';
import 'package:timbangan_spd/app/module/Login/controller/login_controller.dart';
import 'package:timbangan_spd/sidebar.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _ctrl = Get.find<DashboardController>();
  final Map<int, String> _webViewIds = {};
  bool _webViewsInitialized = false;
  Worker? _scalesWorker;

  @override
  void initState() {
    super.initState();
    if (_ctrl.scales.isNotEmpty) {
      _webViewsInitialized = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _initializeWebViews());
      return;
    }
    _scalesWorker = ever(_ctrl.scales, (_) {
      if (!_webViewsInitialized && _ctrl.scales.isNotEmpty) {
        _webViewsInitialized = true;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _initializeWebViews());
      }
    });
  }

  @override
  void dispose() {
    _scalesWorker?.dispose();
    super.dispose();
  }

  void _initializeWebViews() {
    for (int i = 0; i < _ctrl.scales.length; i++) {
      final scale = _ctrl.scales[i];
      final viewId = 'scale-webview-${scale.id}';
      _webViewIds[i] = viewId;
      _createWebViewElement(viewId, scale, i);
    }
    if (mounted) setState(() {});
  }

  void _createWebViewElement(String viewId, ScaleDevice scale, int index) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = 'http://${scale.ip}/project/apps/index#page=1&now=$timestamp';

    final iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = '16px'
      ..style.pointerEvents = 'none'; // ✅ iframe tidak bisa diklik

    iframe.onLoad.listen((_) {
      if (!mounted) return;
      final idx = _getScaleIndex(scale.id);
      if (idx != -1) _ctrl.updateScaleStatus(idx, ScaleStatus.online);
    });

    iframe.onError.listen((_) {
      if (!mounted) return;
      final idx = _getScaleIndex(scale.id);
      if (idx != -1) _ctrl.updateScaleStatus(idx, ScaleStatus.offline);
    });

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int _) {
        Future.microtask(() => iframe.src = url);
        return iframe;
      },
    );
  }

  int _getScaleIndex(int scaleId) {
    if (!mounted) return -1;
    return _ctrl.scales.indexWhere((s) => s.id == scaleId);
  }

  void _refreshWebView(int index) {
    final scale = _ctrl.scales[index];
    final newId =
        'scale-webview-${scale.id}-${DateTime.now().millisecondsSinceEpoch}';
    _ctrl.updateScaleStatus(index, ScaleStatus.loading);
    _ctrl.checkDeviceStatus(index);
    _createWebViewElement(newId, scale, index);
    setState(() => _webViewIds[index] = newId);
  }

  void _refreshAllWebViews() {
    for (int i = 0; i < _ctrl.scales.length; i++) _refreshWebView(i);
    _ctrl.refreshDevices();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Dashboard',
      child: Column(children: [
        _TopBar(onRefresh: _refreshAllWebViews),
        Expanded(
          child: Obx(() {
            if (_ctrl.isLoading.value) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }
            return _buildBody(context);
          }),
        ),
      ]),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Obx(() => GridView.builder(
            // ✅ 2 kolom tetap (mobile 1 kolom)
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 16 / 10,
            ),
            itemCount: _ctrl.scales.length,
            itemBuilder: (context, index) =>
                _buildDeviceCard(_ctrl.scales[index], index),
          )),
    );
  }

  Widget _buildDeviceCard(ScaleDevice scale, int index) {
    final viewId = _webViewIds[index] ?? 'scale-webview-${scale.id}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            elevation: 3,
            shadowColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(children: [
                // ── Iframe mesin ─────────────────────────────────────────
                Positioned.fill(child: HtmlElementView(viewType: viewId)),

                Positioned.fill(
                  child: MouseRegion(
                    cursor:
                        SystemMouseCursors.basic, 
                    child: GestureDetector(
                      onTap: () {},
                      onDoubleTap: () {},
                      onLongPress: () {},
                      onPanStart: (_) {},
                      onPanUpdate: (_) {},
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),

                // ── Overlay status jika tidak online ──────────────────────
                if (scale.status != ScaleStatus.online)
                  Positioned.fill(child: _buildStatusWidget(scale)),

                // ── Header overlay ─────────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(scale.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            Text(scale.ip,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                      // Status dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(scale.status),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(scale.status)
                                  .withOpacity(0.6),
                              blurRadius: 6,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ✅ Hanya tombol ini yang bisa diklik
                      GestureDetector(
                        onTap: () => _refreshWebView(index),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Info bawah card ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 6),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _getStatusColor(scale.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: _getStatusColor(scale.status).withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(scale.status)),
                ),
                const SizedBox(width: 4),
                Text(_getStatusLabel(scale.status),
                    style: TextStyle(
                        color: _getStatusColor(scale.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scale.name,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHead)),
                  Text('PT. PULAU SAMBU (GUNTUNG) · ${scale.ip}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildStatusWidget(ScaleDevice scale) {
    switch (scale.status) {
      case ScaleStatus.loading:
        return Container(
          color: AppColors.primaryLight,
          child: const Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 12),
              Text('Connecting...',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      case ScaleStatus.warning:
        return Container(
          color: const Color(0xFFFFF8E8),
          child: const Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.warning_amber_rounded,
                  size: 40, color: Color(0xFFF59E0B)),
              SizedBox(height: 8),
              Text('WARNING',
                  style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        );
      case ScaleStatus.offline:
      default:
        return Container(
          color: AppColors.dangerLight,
          child: const Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.signal_wifi_off, size: 40, color: AppColors.danger),
              SizedBox(height: 8),
              Text('NO SIGNAL',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        );
    }
  }

  Color _getStatusColor(ScaleStatus status) {
    switch (status) {
      case ScaleStatus.online:
        return const Color(0xFF34C679);
      case ScaleStatus.loading:
        return AppColors.primary;
      case ScaleStatus.warning:
        return const Color(0xFFF59E0B);
      case ScaleStatus.offline:
        return AppColors.danger;
    }
  }

  String _getStatusLabel(ScaleStatus status) {
    switch (status) {
      case ScaleStatus.online:
        return 'Online';
      case ScaleStatus.loading:
        return 'Connecting';
      case ScaleStatus.warning:
        return 'Warning';
      case ScaleStatus.offline:
        return 'Offline';
    }
  }
}

// ─────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────
class _TopBar extends StatefulWidget {
  final VoidCallback onRefresh;
  const _TopBar({required this.onRefresh});
  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      padding:
          EdgeInsets.fromLTRB(isMobile ? 12 : 20, 14, isMobile ? 12 : 20, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 20, vertical: 12),
          child: Row(children: [
            if (!isMobile)
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF4F6EF7), Color(0xFF7B52F5)],
                ).createShader(bounds),
                child: const Text('Device Monitoring',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                DateFormat(
                  isMobile
                      ? 'dd MMM yyyy  HH:mm:ss'
                      : 'EEEE, dd MMM yyyy  HH:mm:ss',
                  'id',
                ).format(_now),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.primary,
              tooltip: 'Refresh semua',
            ),
            const SizedBox(width: 4),
            _UserProfileButton(),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// User Profile Button
// ─────────────────────────────────────────────
class _UserProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loginCtrl = Get.find<LoginController>();
    return Obx(() => PopupMenuButton(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border)),
            child: Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Text(
                  (loginCtrl.loggedInUser.value ?? 'U')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loginCtrl.loggedInUser.value ?? 'User',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12)),
                  const Text('PT. Pulau Sambu',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ]),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => loginCtrl.logout(),
              child: const Row(children: [
                Icon(Icons.logout_rounded, color: AppColors.danger, size: 16),
                SizedBox(width: 10),
                Text('Logout', style: TextStyle(color: AppColors.danger)),
              ]),
            ),
          ],
        ));
  }
}
