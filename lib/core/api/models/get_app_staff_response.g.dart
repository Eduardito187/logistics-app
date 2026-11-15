// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_staff_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppStaffResponse _$GetAppStaffResponseFromJson(Map<String, dynamic> json) =>
    GetAppStaffResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetAppStaffResponseToJson(
  GetAppStaffResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
