// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_node_receptions_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppNodeReceptionsResponse _$GetAppNodeReceptionsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppNodeReceptionsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => NodeReceptionSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppNodeReceptionsResponseToJson(
  GetAppNodeReceptionsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
