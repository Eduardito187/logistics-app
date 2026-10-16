// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  status: UserStatus.fromJson(json['status'] as String),
  roleKeys: (json['role_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  lastLoginAt: json['last_login_at'] == null
      ? null
      : DateTime.parse(json['last_login_at'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'status': instance.status,
  'role_keys': instance.roleKeys,
  'last_login_at': instance.lastLoginAt?.toIso8601String(),
};
