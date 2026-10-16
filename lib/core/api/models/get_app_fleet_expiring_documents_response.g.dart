// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleet_expiring_documents_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetExpiringDocumentsResponse
_$GetAppFleetExpiringDocumentsResponseFromJson(Map<String, dynamic> json) =>
    GetAppFleetExpiringDocumentsResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ExpiringDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : CollectionMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetAppFleetExpiringDocumentsResponseToJson(
  GetAppFleetExpiringDocumentsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
