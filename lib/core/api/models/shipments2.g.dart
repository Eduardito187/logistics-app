// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipments2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Shipments2 _$Shipments2FromJson(Map<String, dynamic> json) => Shipments2(
  shipmentId: json['shipment_id'] as String?,
  externalId: json['external_id'] as String?,
  customerName: json['customer_name'] as String?,
  status: json['status'] as String?,
  currentDate: json['current_date'] == null
      ? null
      : DateTime.parse(json['current_date'] as String),
  currentWindowStart: json['current_window_start'] as String?,
  currentWindowEnd: json['current_window_end'] as String?,
);

Map<String, dynamic> _$Shipments2ToJson(Shipments2 instance) =>
    <String, dynamic>{
      'shipment_id': instance.shipmentId,
      'external_id': instance.externalId,
      'customer_name': instance.customerName,
      'status': instance.status,
      'current_date': instance.currentDate?.toIso8601String(),
      'current_window_start': instance.currentWindowStart,
      'current_window_end': instance.currentWindowEnd,
    };
