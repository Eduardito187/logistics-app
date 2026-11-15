// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_fitness.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleFitness _$VehicleFitnessFromJson(Map<String, dynamic> json) =>
    VehicleFitness(
      vehicleId: json['vehicle_id'] as String,
      plate: json['plate'] as String,
      date: DateTime.parse(json['date'] as String),
      fitToDispatch: json['fit_to_dispatch'] as bool,
      unfitSince: json['unfit_since'] == null
          ? null
          : DateTime.parse(json['unfit_since'] as String),
      unfitReason: json['unfit_reason'] as String?,
      unfitItems: (json['unfit_items'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$VehicleFitnessToJson(VehicleFitness instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'plate': instance.plate,
      'date': instance.date.toIso8601String(),
      'fit_to_dispatch': instance.fitToDispatch,
      'unfit_since': instance.unfitSince?.toIso8601String(),
      'unfit_reason': instance.unfitReason,
      'unfit_items': instance.unfitItems,
    };
