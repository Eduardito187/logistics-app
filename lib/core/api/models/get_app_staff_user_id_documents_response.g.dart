// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_staff_user_id_documents_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppStaffUserIdDocumentsResponse _$GetAppStaffUserIdDocumentsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppStaffUserIdDocumentsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => StaffDocument.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppStaffUserIdDocumentsResponseToJson(
  GetAppStaffUserIdDocumentsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
