// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_shipments_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppShipmentsResponse _$GetAppShipmentsResponseFromJson(
  Map<String, dynamic> json,
) => GetAppShipmentsResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : MetaSealed.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppShipmentsResponseToJson(
  GetAppShipmentsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
