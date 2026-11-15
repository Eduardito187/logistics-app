// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_capacity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripCapacity _$TripCapacityFromJson(Map<String, dynamic> json) => TripCapacity(
  usedUnits: (json['used_units'] as num).toInt(),
  usedKg: (json['used_kg'] as num).toDouble(),
  usedM3: (json['used_m3'] as num).toDouble(),
  maxUnits: (json['max_units'] as num?)?.toInt(),
  maxKg: (json['max_kg'] as num?)?.toDouble(),
  maxM3: (json['max_m3'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TripCapacityToJson(TripCapacity instance) =>
    <String, dynamic>{
      'used_units': instance.usedUnits,
      'max_units': instance.maxUnits,
      'used_kg': instance.usedKg,
      'max_kg': instance.maxKg,
      'used_m3': instance.usedM3,
      'max_m3': instance.maxM3,
    };
