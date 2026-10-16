// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleProfile _$VehicleProfileFromJson(Map<String, dynamic> json) =>
    VehicleProfile(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      year: (json['year'] as num?)?.toInt(),
      fuelType: json['fuel_type'] == null
          ? null
          : FuelType.fromJson(json['fuel_type'] as String),
      tankLiters: (json['tank_liters'] as num?)?.toDouble(),
      vin: json['vin'] as String?,
      color: json['color'] as String?,
      currentOdometerKm: (json['current_odometer_km'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VehicleProfileToJson(VehicleProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'brand': instance.brand,
      'model': instance.model,
      'year': instance.year,
      'fuel_type': instance.fuelType,
      'tank_liters': instance.tankLiters,
      'vin': instance.vin,
      'color': instance.color,
      'current_odometer_km': instance.currentOdometerKm,
    };
