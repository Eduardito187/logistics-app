// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipments.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Shipments _$ShipmentsFromJson(Map<String, dynamic> json) => Shipments(
  shipmentId: json['shipment_id'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$ShipmentsToJson(Shipments instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'status': instance.status,
};
