// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stops.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stops _$StopsFromJson(Map<String, dynamic> json) => Stops(
  shipmentId: json['shipment_id'] as String,
  sequence: (json['sequence'] as num).toInt(),
  orderReference: json['order_reference'] as String?,
  customerName: json['customer_name'] as String?,
  address: json['address'] as String?,
  etaAt: json['eta_at'] == null
      ? null
      : DateTime.parse(json['eta_at'] as String),
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$StopsToJson(Stops instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'sequence': instance.sequence,
  'order_reference': instance.orderReference,
  'customer_name': instance.customerName,
  'address': instance.address,
  'eta_at': instance.etaAt?.toIso8601String(),
  'lat': instance.lat,
  'lng': instance.lng,
};
