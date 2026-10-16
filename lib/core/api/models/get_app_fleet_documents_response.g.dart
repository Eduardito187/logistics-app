// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleet_documents_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetDocumentsResponse _$GetAppFleetDocumentsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetDocumentsResponse(
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => FleetDocument.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : CollectionMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppFleetDocumentsResponseToJson(
  GetAppFleetDocumentsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
