// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_access_permissions_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppAccessPermissionsResponse _$GetAppAccessPermissionsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppAccessPermissionsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Permission.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppAccessPermissionsResponseToJson(
  GetAppAccessPermissionsResponse instance,
) => <String, dynamic>{'data': instance.data};
