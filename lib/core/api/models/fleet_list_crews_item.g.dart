// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_list_crews_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetListCrewsItem _$FleetListCrewsItemFromJson(Map<String, dynamic> json) =>
    FleetListCrewsItem(
      id: json['id'] as String?,
      assembledFor: json['assembled_for'] == null
          ? null
          : DateTime.parse(json['assembled_for'] as String),
      vehicleId: json['vehicle_id'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      helpers: (json['helpers'] as List<dynamic>?)
          ?.map((e) => Helpers.fromJson(e as Map<String, dynamic>))
          .toList(),
      shiftStartsAt: json['shift_starts_at'] == null
          ? null
          : DateTime.parse(json['shift_starts_at'] as String),
      shiftEndsAt: json['shift_ends_at'] == null
          ? null
          : DateTime.parse(json['shift_ends_at'] as String),
    );

Map<String, dynamic> _$FleetListCrewsItemToJson(FleetListCrewsItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'assembled_for': instance.assembledFor?.toIso8601String(),
      'vehicle_id': instance.vehicleId,
      'vehicle_plate': instance.vehiclePlate,
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'helpers': instance.helpers,
      'shift_starts_at': instance.shiftStartsAt?.toIso8601String(),
      'shift_ends_at': instance.shiftEndsAt?.toIso8601String(),
    };
