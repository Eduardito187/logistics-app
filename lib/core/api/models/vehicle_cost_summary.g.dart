// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_cost_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleCostSummary _$VehicleCostSummaryFromJson(Map<String, dynamic> json) =>
    VehicleCostSummary(
      vehicleId: json['vehicle_id'] as String,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      fuelCents: (json['fuel_cents'] as num).toInt(),
      maintenanceCents: (json['maintenance_cents'] as num).toInt(),
      expensesCents: (json['expenses_cents'] as num).toInt(),
      totalCents: (json['total_cents'] as num).toInt(),
      currency: json['currency'] as String,
      kilometers: (json['kilometers'] as num).toInt(),
      costPerKmCents: (json['cost_per_km_cents'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VehicleCostSummaryToJson(VehicleCostSummary instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'fuel_cents': instance.fuelCents,
      'maintenance_cents': instance.maintenanceCents,
      'expenses_cents': instance.expensesCents,
      'total_cents': instance.totalCents,
      'currency': instance.currency,
      'kilometers': instance.kilometers,
      'cost_per_km_cents': instance.costPerKmCents,
    };
