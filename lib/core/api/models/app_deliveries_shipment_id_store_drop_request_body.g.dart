// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_deliveries_shipment_id_store_drop_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppDeliveriesShipmentIdStoreDropRequestBody
_$AppDeliveriesShipmentIdStoreDropRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppDeliveriesShipmentIdStoreDropRequestBody(
  nodeId: json['node_id'] as String?,
  photoPath: json['photo_path'] as String?,
  occurredAt: json['occurred_at'] == null
      ? null
      : DateTime.parse(json['occurred_at'] as String),
  lat: json['lat'] as num?,
  lng: json['lng'] as num?,
);

Map<String, dynamic> _$AppDeliveriesShipmentIdStoreDropRequestBodyToJson(
  AppDeliveriesShipmentIdStoreDropRequestBody instance,
) => <String, dynamic>{
  'node_id': instance.nodeId,
  'photo_path': instance.photoPath,
  'occurred_at': instance.occurredAt?.toIso8601String(),
  'lat': instance.lat,
  'lng': instance.lng,
};
