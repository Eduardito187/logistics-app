// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stops2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stops2 _$Stops2FromJson(Map<String, dynamic> json) => Stops2(
  shipmentId: json['shipment_id'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$Stops2ToJson(Stops2 instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
