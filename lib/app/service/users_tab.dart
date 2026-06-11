import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timbangan_spd/app/models/auth_models.dart';
import 'package:timbangan_spd/app/module/Admin/admin_controller.dart';
import 'package:timbangan_spd/app/widget/app_widget.dart';

class UsersTab extends StatelessWidget {
  final AdminController ctrl;
  const UsersTab({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _Toolbar(ctrl: ctrl),
      Expanded(
        child: Obx(() {
          if (ctrl.isLoadingUsers.value) return const AppLoadingView();
          if (ctrl.userError.value != null) {
            return _ErrorView(
              message: ctrl.userError.value!,
              onRetry: ctrl.fetchUsers,
            );
          }
          if (ctrl.filteredUsers.isEmpty) {
            return const AppEmptyView(message: 'Belum ada data user');
          }
          return _UserList(ctrl: ctrl);
        }),
      ),
    ]);
  }
}

// ── Toolbar ───────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final AdminController ctrl;
  const _Toolbar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      color: Colors.white,
      child: Row(children: [
        // Search
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(children: [
              const SizedBox(width: 12),
              const Icon(Icons.search_rounded, size: 15, color: Color(0xFFADB5BD)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (v) => ctrl.userSearch.value = v,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1A1D23)),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama, username, email...',
                    hintStyle: TextStyle(
                        color: Color(0xFFADB5BD), fontSize: 12.5),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 10),

        // User count
        Obx(() => Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFD4DCFF)),
              ),
              child: Row(children: [
                const Icon(Icons.people_outline_rounded,
                    size: 14, color: Color(0xFF4F69F5)),
                const SizedBox(width: 6),
                Text('${ctrl.users.length} user',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F69F5))),
              ]),
            )),
        const SizedBox(width: 10),

        // Add button
        GestureDetector(
          onTap: () => _showCreateDialog(context, ctrl),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF4F69F5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_rounded, size: 15, color: Colors.white),
                SizedBox(width: 5),
                Text('Tambah User',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _showCreateDialog(BuildContext context, AdminController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _CreateUserDialog(ctrl: ctrl),
    );
  }
}

// ── User List ─────────────────────────────────────────────────────────────────
class _UserList extends StatelessWidget {
  final AdminController ctrl;
  const _UserList({required this.ctrl});

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(children: [
                SizedBox(width: 32, child: _H('NO')),
                SizedBox(width: 10),
                SizedBox(width: 30),
                SizedBox(width: 10),
                Expanded(flex: 3, child: _H('NAMA / EMAIL')),
                SizedBox(width: 10),
                Expanded(flex: 2, child: _H('USERNAME')),
                SizedBox(width: 10),
                SizedBox(width: 130, child: _H('ROLE', center: true)),
                SizedBox(width: 10),
                SizedBox(width: 160, child: _H('GANTI ROLE', center: true)),
                SizedBox(width: 10),
                SizedBox(width: 80, child: _H('STATUS', center: true)),
                SizedBox(width: 10),
                SizedBox(width: 90, child: _H('BERGABUNG', center: true)),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFEEF0F5)),
            Expanded(
              child: Obx(() => ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    itemCount: ctrl.filteredUsers.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: Color(0xFFEEF0F5)),
                    itemBuilder: (_, i) => _UserRow(
                      user: ctrl.filteredUsers[i],
                      index: i + 1,
                      ctrl: ctrl,
                    ),
                  )),
            ),
          ]),
        ),
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String text;
  final bool center;
  const _H(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.4));
  }
}

// ── User Row ──────────────────────────────────────────────────────────────────
class _UserRow extends StatefulWidget {
  final UserListModel user;
  final int index;
  final AdminController ctrl;
  const _UserRow(
      {required this.user, required this.index, required this.ctrl});

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  static Color roleColor(String role) => role == 'Programmer'
      ? const Color(0xFF0369A1)
      : const Color(0xFF6D28D9);

  static IconData roleIcon(String role) => role == 'Programmer'
      ? Icons.code_rounded
      : Icons.shield_rounded;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final rc = roleColor(u.role);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? const Color(0xFFF8F9FC) : Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

          // Avatar
          CircleAvatar(
            radius: 15,
            backgroundColor: rc.withOpacity(0.1),
            child: Text(
              u.nama.isNotEmpty ? u.nama[0].toUpperCase() : '?',
              style: TextStyle(
                  color: rc, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),

          // Nama / Email
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nama,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D23))),
                Text(u.email,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Username
          Expanded(
            flex: 2,
            child: Text('@${u.username}',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563)),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),

          // Role badge
          SizedBox(
            width: 130,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rc.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon(u.role), size: 11, color: rc),
                    const SizedBox(width: 4),
                    Text(u.role,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: rc)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Role dropdown
          SizedBox(
            width: 160,
            child: Center(
              child: _RoleDropdown(
                userId: u.id,
                currentRole: u.role,
                ctrl: widget.ctrl,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Status toggle
          SizedBox(
            width: 80,
            child: Center(
              child: GestureDetector(
                onTap: () => widget.ctrl.updateStatus(u.id, !u.aktif),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: u.aktif
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: u.aktif
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: u.aktif
                              ? const Color(0xFF059669)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        u.aktif ? 'Aktif' : 'Off',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: u.aktif
                                ? const Color(0xFF065F46)
                                : const Color(0xFF991B1B)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Bergabung
          SizedBox(
            width: 90,
            child: Text(
              DateFormat('dd MMM yy', 'id_ID').format(u.createdAt),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Role Dropdown ─────────────────────────────────────────────────────────────
class _RoleDropdown extends StatelessWidget {
  final int userId;
  final String currentRole;
  final AdminController ctrl;
  const _RoleDropdown(
      {required this.userId,
      required this.currentRole,
      required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentRole,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded,
              size: 14, color: Color(0xFFADB5BD)),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(9),
          items: AdminController.validRoles
              .map((r) => DropdownMenuItem<String>(
                    value: r,
                    child: Text(r,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: r == 'Programmer'
                                ? const Color(0xFF0369A1)
                                : const Color(0xFF6D28D9))),
                  ))
              .toList(),
          onChanged: (role) {
            if (role != null && role != currentRole) {
              ctrl.updateRole(userId, role);
            }
          },
        ),
      ),
    );
  }
}

// ── Create User Dialog ────────────────────────────────────────────────────────
class _CreateUserDialog extends StatefulWidget {
  final AdminController ctrl;
  const _CreateUserDialog({required this.ctrl});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _namaC  = TextEditingController();
  final _emailC = TextEditingController();
  final _userC  = TextEditingController();
  final _passC  = TextEditingController();
  String _role     = 'Programmer';
  bool   _loading  = false;
  bool   _showPass = false;

  @override
  void dispose() {
    _namaC.dispose();
    _emailC.dispose();
    _userC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_namaC.text.trim().isEmpty ||
        _emailC.text.trim().isEmpty ||
        _userC.text.trim().isEmpty ||
        _passC.text.isEmpty) {
      Get.snackbar('Validasi', 'Semua field wajib diisi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFEF3C7),
          colorText: const Color(0xFF92400E),
          margin: const EdgeInsets.all(16),
          borderRadius: 10);
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.ctrl.createUser(
      nama: _namaC.text.trim(),
      email: _emailC.text.trim(),
      username: _userC.text.trim(),
      password: _passC.text,
      role: _role,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                    bottom: BorderSide(color: Color(0xFFEEF0F5))),
              ),
              child: Row(children: [
                const Icon(Icons.person_add_outlined,
                    size: 18, color: Color(0xFF4F69F5)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Tambah User Baru',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1D23))),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFF9CA3AF)),
                ),
              ]),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _FormField(
                  ctrl: _namaC,
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _FormField(
                  ctrl: _emailC,
                  label: 'Email',
                  hint: 'user@domain.com',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _FormField(
                  ctrl: _userC,
                  label: 'Username',
                  hint: 'username unik',
                  icon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 12),

                // Password
                _FormLabel(label: 'Password'),
                const SizedBox(height: 5),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 15, color: Color(0xFFADB5BD)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _passC,
                        obscureText: !_showPass,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF1A1D23)),
                        decoration: const InputDecoration(
                          hintText: 'Min. 6 karakter',
                          hintStyle: TextStyle(
                              color: Color(0xFFADB5BD), fontSize: 12.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showPass = !_showPass),
                      child: Icon(
                          _showPass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 15,
                          color: const Color(0xFFADB5BD)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // Role selector
                _FormLabel(label: 'Role'),
                const SizedBox(height: 6),
                Row(
                  children: AdminController.validRoles.map((r) {
                    final sel = _role == r;
                    final color = r == 'Programmer'
                        ? const Color(0xFF0369A1)
                        : const Color(0xFF6D28D9);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          margin: EdgeInsets.only(
                              right: r == AdminController.validRoles.last
                                  ? 0
                                  : 8),
                          height: 38,
                          decoration: BoxDecoration(
                            color: sel
                                ? color.withOpacity(0.1)
                                : const Color(0xFFF8F9FC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sel ? color : const Color(0xFFE5E7EB),
                                width: sel ? 1.5 : 1),
                          ),
                          child: Center(
                            child: Text(r,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? color
                                        : const Color(0xFF9CA3AF))),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Text('Batal',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _loading ? null : _submit,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _loading
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF4F69F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF9CA3AF)))
                            : const Text('Buat User',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280))),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType type;
  const _FormField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label: label),
        const SizedBox(height: 5),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(children: [
            Icon(icon, size: 15, color: const Color(0xFFADB5BD)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: type,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF1A1D23)),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                      color: Color(0xFFADB5BD), fontSize: 12.5),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 40, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F69F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Coba Lagi',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}