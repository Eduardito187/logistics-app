// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data9.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data9 _$Data9FromJson(Map<String, dynamic> json) => Data9(
  shipmentId: json['shipment_id'] as String,
  units: (json['units'] as List<dynamic>)
      .map((e) => UnitTracking.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Data9ToJson(Data9 instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'units': instance.units,
};
