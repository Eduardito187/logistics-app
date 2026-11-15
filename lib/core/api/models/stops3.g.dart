// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stops3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stops3 _$Stops3FromJson(Map<String, dynamic> json) => Stops3(
  shipmentId: json['shipment_id'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$Stops3ToJson(Stops3 instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
