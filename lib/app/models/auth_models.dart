// lib/app/models/auth_models.dart

class UserListModel {
  final int       id;
  final String    nama;
  final String    email;
  final String    username;
  final String    role;
  final bool      aktif;
  final DateTime  createdAt;
  final DateTime? updatedAt;

  UserListModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.username,
    required this.role,
    required this.aktif,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserListModel.fromJson(Map<String, dynamic> json) => UserListModel(
        id:        json['id'] as int,
        nama:      json['nama'] as String,
        email:     json['email'] as String,
        username:  json['username'] as String,
        role:      json['role'] as String,
        aktif:     json['aktif'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}

class ActivityLogModel {
  final int       id;
  final int       userId;
  final String?   namaUser;
  final String?   usernameUser;
  final String    action;
  final String?   ipAddress;
  final String?   userAgent;
  final DateTime  createdAt;

  ActivityLogModel({
    required this.id,
    required this.userId,
    this.namaUser,
    this.usernameUser,
    required this.action,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) =>
      ActivityLogModel(
        id:           json['id'] as int,
        userId:       json['userId'] as int,
        namaUser:     json['namaUser'] as String?,
        usernameUser: json['usernameUser'] as String?,
        action:       json['action'] as String,
        ipAddress:    json['ipAddress'] as String?,
        userAgent:    json['userAgent'] as String?,
        createdAt:    DateTime.parse(json['createdAt'] as String),
      );
}

class MenuModel {
  final int     id;
  final String  namaMenu;
  final String  path;
  final String? icon;
  final bool    aktif;
  final int     urutan;
  List<String>  roles; // mutable — dipakai admin_controller.dart

  MenuModel({
    required this.id,
    required this.namaMenu,
    required this.path,
    this.icon,
    required this.aktif,
    required this.urutan,
    required this.roles,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) => MenuModel(
        id:       json['id'] as int,
        namaMenu: json['namaMenu'] as String,
        path:     json['path'] as String,
        icon:     json['icon'] as String?,
        aktif:    json['aktif'] as bool,
        urutan:   json['urutan'] as int,
        roles:    (json['roles'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  [],
      );
}

class LoginResponse {
  final int      userId;
  final String   nama;
  final String   username;
  final String   email;
  final String   role;
  final String   accessToken;
  final String   refreshToken;
  final DateTime accessTokenExpiry;
  final DateTime refreshTokenExpiry;

  LoginResponse({
    required this.userId,
    required this.nama,
    required this.username,
    required this.email,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        userId:             json['userId'] as int,
        nama:               json['nama'] as String,
        username:           json['username'] as String,
        email:              json['email'] as String,
        role:               json['role'] as String,
        accessToken:        json['accessToken'] as String,
        refreshToken:       json['refreshToken'] as String,
        accessTokenExpiry:  DateTime.parse(json['accessTokenExpiry'] as String),
        refreshTokenExpiry: DateTime.parse(json['refreshTokenExpiry'] as String),
      );
}