// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'define_vehicle_profile_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefineVehicleProfileRequest _$DefineVehicleProfileRequestFromJson(
  Map<String, dynamic> json,
) => DefineVehicleProfileRequest(
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
);

Map<String, dynamic> _$DefineVehicleProfileRequestToJson(
  DefineVehicleProfileRequest instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'brand': instance.brand,
  'model': instance.model,
  'year': instance.year,
  'fuel_type': instance.fuelType,
  'tank_liters': instance.tankLiters,
  'vin': instance.vin,
  'color': instance.color,
};
