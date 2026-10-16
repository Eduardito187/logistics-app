// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_access_roles_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppAccessRolesResponse _$GetAppAccessRolesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppAccessRolesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Role.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppAccessRolesResponseToJson(
  GetAppAccessRolesResponse instance,
) => <String, dynamic>{'data': instance.data};
