// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_refuel_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordRefuelRequest _$RecordRefuelRequestFromJson(Map<String, dynamic> json) =>
    RecordRefuelRequest(
      vehicleId: json['vehicle_id'] as String,
      fuelType: FuelType.fromJson(json['fuel_type'] as String),
      liters: (json['liters'] as num).toDouble(),
      pricePerLiterCents: (json['price_per_liter_cents'] as num).toInt(),
      currency: json['currency'] as String,
      fullTank: json['full_tank'] as bool,
      refueledAt: DateTime.parse(json['refueled_at'] as String),
      driverId: json['driver_id'] as String?,
      odometerKm: (json['odometer_km'] as num?)?.toInt(),
      station: json['station'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$RecordRefuelRequestToJson(
  RecordRefuelRequest instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'fuel_type': instance.fuelType,
  'liters': instance.liters,
  'price_per_liter_cents': instance.pricePerLiterCents,
  'currency': instance.currency,
  'odometer_km': instance.odometerKm,
  'station': instance.station,
  'full_tank': instance.fullTank,
  'refueled_at': instance.refueledAt.toIso8601String(),
  'note': instance.note,
};
