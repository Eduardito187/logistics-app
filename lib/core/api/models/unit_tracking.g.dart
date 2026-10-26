// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitTracking _$UnitTrackingFromJson(Map<String, dynamic> json) => UnitTracking(
  id: json['id'] as String,
  unitId: json['unit_id'] as String,
  shipmentId: json['shipment_id'] as String,
  status: UnitStatus.fromJson(json['status'] as String),
  lastLocationId: json['last_location_id'] as String?,
  lastSeenAt: json['last_seen_at'] == null
      ? null
      : DateTime.parse(json['last_seen_at'] as String),
  label: json['label'] as String?,
  sku: json['sku'] as String?,
  productName: json['product_name'] as String?,
  productImageUrl: json['product_image_url'] as String?,
  pieceIndex: (json['piece_index'] as num?)?.toInt(),
  pieceTotal: (json['piece_total'] as num?)?.toInt(),
);

Map<String, dynamic> _$UnitTrackingToJson(UnitTracking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unit_id': instance.unitId,
      'shipment_id': instance.shipmentId,
      'status': instance.status,
      'last_location_id': instance.lastLocationId,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'label': instance.label,
      'sku': instance.sku,
      'product_name': instance.productName,
      'product_image_url': instance.productImageUrl,
      'piece_index': instance.pieceIndex,
      'piece_total': instance.pieceTotal,
    };
