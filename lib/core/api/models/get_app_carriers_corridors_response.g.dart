// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_carriers_corridors_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppCarriersCorridorsResponse _$GetAppCarriersCorridorsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppCarriersCorridorsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => CarrierCorridor.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppCarriersCorridorsResponseToJson(
  GetAppCarriersCorridorsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
