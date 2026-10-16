// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_access_users_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppAccessUsersResponse _$GetAppAccessUsersResponseFromJson(
  Map<String, dynamic> json,
) => GetAppAccessUsersResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => User.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppAccessUsersResponseToJson(
  GetAppAccessUsersResponse instance,
) => <String, dynamic>{'data': instance.data};
