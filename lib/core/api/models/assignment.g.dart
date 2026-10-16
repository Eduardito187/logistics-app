// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Assignment _$AssignmentFromJson(Map<String, dynamic> json) => Assignment(
  volumeM3: (json['volume_m3'] as num).toDouble(),
  vehicleClass: VehicleClass.fromJson(json['vehicle_class'] as String),
  tariff: json['tariff'] == null
      ? null
      : Tariff.fromJson(json['tariff'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AssignmentToJson(Assignment instance) =>
    <String, dynamic>{
      'volume_m3': instance.volumeM3,
      'vehicle_class': instance.vehicleClass,
      'tariff': instance.tariff,
    };
