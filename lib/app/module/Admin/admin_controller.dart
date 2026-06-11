import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timbangan_spd/app/models/auth_models.dart';
import 'package:timbangan_spd/app/module/Admin/admin_service.dart';

class AdminController extends GetxController {
  // ── Tab ───────────────────────────────────────────────────────────────────
  final selectedTab = 0.obs;

  // ── Users ─────────────────────────────────────────────────────────────────
  final users          = <UserListModel>[].obs;
  final isLoadingUsers = false.obs;
  final userError      = RxnString();
  final userSearch     = ''.obs;

  List<UserListModel> get filteredUsers {
    final q = userSearch.value.toLowerCase().trim();
    if (q.isEmpty) return users;
    return users
        .where((u) =>
            u.nama.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }

  // ── Menus ─────────────────────────────────────────────────────────────────
  final menus          = <MenuModel>[].obs;
  final isLoadingMenus = false.obs;
  final menuError      = RxnString();

  // ── Activity Logs ─────────────────────────────────────────────────────────
  final logs          = <ActivityLogModel>[].obs;
  final isLoadingLogs = false.obs;
  final logError      = RxnString();
  final logFilterUser = Rxn<int>();
  final logStartDate  = Rx<DateTime?>(
      DateTime.now().subtract(const Duration(days: 7)));
  final logEndDate    = Rx<DateTime?>(DateTime.now());

  static const validRoles = ['Administrator', 'Programmer'];

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    fetchMenus();
  }

  // ── FETCH USERS ───────────────────────────────────────────────────────────
  Future<void> fetchUsers() async {
    isLoadingUsers.value = true;
    userError.value = null;
    try {
      users.value = await AdminService.getAllUsers();
    } catch (e) {
      userError.value = e.toString();
    } finally {
      isLoadingUsers.value = false;
    }
  }

  // ── CREATE USER ───────────────────────────────────────────────────────────
  Future<bool> createUser({
    required String nama,
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      await AdminService.createUser(
        nama: nama,
        email: email,
        username: username,
        password: password,
        role: role,
      );
      await fetchUsers();
      _toast('Berhasil', 'User "$nama" berhasil dibuat', true);
      return true;
    } catch (e) {
      _toast('Gagal', e.toString(), false);
      return false;
    }
  }

  // ── UPDATE ROLE ───────────────────────────────────────────────────────────
  Future<void> updateRole(int userId, String role) async {
    try {
      await AdminService.updateRole(userId, role);
      final idx = users.indexWhere((u) => u.id == userId);
      if (idx >= 0) {
        final old = users[idx];
        users[idx] = UserListModel(
          id: old.id,
          nama: old.nama,
          email: old.email,
          username: old.username,
          role: role,
          aktif: old.aktif,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        users.refresh();
      }
      _toast('Berhasil', 'Role diubah ke $role', true);
    } catch (e) {
      _toast('Gagal', e.toString(), false);
    }
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<void> updateStatus(int userId, bool aktif) async {
    try {
      await AdminService.updateStatus(userId, aktif);
      final idx = users.indexWhere((u) => u.id == userId);
      if (idx >= 0) {
        final old = users[idx];
        users[idx] = UserListModel(
          id: old.id,
          nama: old.nama,
          email: old.email,
          username: old.username,
          role: old.role,
          aktif: aktif,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        users.refresh();
      }
      _toast(
        'Berhasil',
        aktif ? 'Akun diaktifkan' : 'Akun dinonaktifkan',
        true,
      );
    } catch (e) {
      _toast('Gagal', e.toString(), false);
    }
  }

  // ── FETCH MENUS ───────────────────────────────────────────────────────────
  Future<void> fetchMenus() async {
    isLoadingMenus.value = true;
    menuError.value = null;
    try {
      menus.value = await AdminService.getAllMenus();
    } catch (e) {
      menuError.value = e.toString();
    } finally {
      isLoadingMenus.value = false;
    }
  }

  // ── UPDATE MENU ROLES ─────────────────────────────────────────────────────
  Future<void> updateMenuRoles(int menuId, List<String> roles) async {
    try {
      await AdminService.updateMenuRoles(menuId, roles);
      final idx = menus.indexWhere((m) => m.id == menuId);
      if (idx >= 0) {
        menus[idx].roles = List<String>.from(roles);
        menus.refresh();
      }
      _toast('Berhasil', 'Akses menu diperbarui', true);
    } catch (e) {
      _toast('Gagal', e.toString(), false);
    }
  }

  // ── FETCH LOGS ────────────────────────────────────────────────────────────
  Future<void> fetchLogs() async {
    isLoadingLogs.value = true;
    logError.value = null;
    try {
      logs.value = await AdminService.getActivityLogs(
        userId: logFilterUser.value,
        startDate: logStartDate.value,
        endDate: logEndDate.value,
      );
    } catch (e) {
      logError.value = e.toString();
    } finally {
      isLoadingLogs.value = false;
    }
  }

  // ── HELPER ────────────────────────────────────────────────────────────────
  void _toast(String title, String msg, bool success) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: Duration(seconds: success ? 3 : 5),
      backgroundColor:
          success ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
      colorText:
          success ? const Color(0xFF065F46) : const Color(0xFF991B1B),
      icon: Icon(
        success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
        color: success ? const Color(0xFF059669) : const Color(0xFFEF4444),
        size: 20,
      ),
    );
  }
}