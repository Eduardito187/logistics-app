// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_utilization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleUtilization _$VehicleUtilizationFromJson(Map<String, dynamic> json) =>
    VehicleUtilization(
      vehicleId: json['vehicle_id'] as String,
      vehiclePlate: json['vehicle_plate'] as String?,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      departuresCount: (json['departures_count'] as num).toInt(),
      kmTraveled: (json['km_traveled'] as num).toInt(),
      hoursOnRoad: json['hours_on_road'] as num,
      lastOdometerKm: (json['last_odometer_km'] as num?)?.toInt(),
      lastOdometerReadAt: json['last_odometer_read_at'] == null
          ? null
          : DateTime.parse(json['last_odometer_read_at'] as String),
    );

Map<String, dynamic> _$VehicleUtilizationToJson(VehicleUtilization instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'vehicle_plate': instance.vehiclePlate,
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'departures_count': instance.departuresCount,
      'km_traveled': instance.kmTraveled,
      'hours_on_road': instance.hoursOnRoad,
      'last_odometer_km': instance.lastOdometerKm,
      'last_odometer_read_at': instance.lastOdometerReadAt?.toIso8601String(),
    };
