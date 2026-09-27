import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Perfil do usuário armazenado na coleção `users`.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final UserRole role;

  /// Créditos de anúncio disponíveis (Fase 6). Cada publicação consome 1.
  /// Todo novo cadastro recebe 1 crédito de boas-vindas — a compra de mais
  /// créditos pelo gateway de pagamento chega na Fase 6.
  final int adCredits;

  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.role = UserRole.user,
    this.adCredits = 1,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  /// Constrói a partir da resposta JSON do backend próprio (Cloudflare
  /// Worker) — formato usado por `/auth/login`, `/auth/register` e `/me`.
  factory UserModel.fromApiJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      photoUrl: (json['photo_url'] ?? json['photoUrl']) as String?,
      role: UserRole.fromString(json['role'] as String?),
      adCredits:
          ((json['ad_credits'] ?? json['adCredits']) as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse((json['created_at'] as String).replaceFirst(' ', 'T'))
          : DateTime.now(),
    );
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      adCredits: (map['adCredits'] as num?)?.toInt() ?? 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.name,
      'adCredits': adCredits,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({String? name, String? phone, String? photoUrl}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      adCredits: adCredits,
      createdAt: createdAt,
    );
  }
}
