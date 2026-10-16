// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUserProfile _$AppUserProfileFromJson(Map<String, dynamic> json) =>
    AppUserProfile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AppUserProfileToJson(AppUserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'roles': instance.roles,
    };
