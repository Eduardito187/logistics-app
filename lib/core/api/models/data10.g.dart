// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data10.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data10 _$Data10FromJson(Map<String, dynamic> json) => Data10(
  shipmentId: json['shipment_id'] as String,
  units: (json['units'] as List<dynamic>)
      .map((e) => UnitTracking.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Data10ToJson(Data10 instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'units': instance.units,
};
