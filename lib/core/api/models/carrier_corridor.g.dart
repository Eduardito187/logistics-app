// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier_corridor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarrierCorridor _$CarrierCorridorFromJson(Map<String, dynamic> json) =>
    CarrierCorridor(
      from: json['from'] as String,
      to: json['to'] as String,
      fromLabel: json['from_label'] as String,
      toLabel: json['to_label'] as String,
      corridorType: CorridorType.fromJson(json['corridor_type'] as String),
      vehicleClasses: (json['vehicle_classes'] as List<dynamic>)
          .map((e) => VehicleClass.fromJson(e as String))
          .toList(),
    );

Map<String, dynamic> _$CarrierCorridorToJson(CarrierCorridor instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'from_label': instance.fromLabel,
      'to_label': instance.toLabel,
      'corridor_type': instance.corridorType,
      'vehicle_classes': instance.vehicleClasses,
    };
