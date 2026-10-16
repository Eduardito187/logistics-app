// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_crew.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyCrew _$MyCrewFromJson(Map<String, dynamic> json) => MyCrew(
  crewId: json['crew_id'] as String,
  date: DateTime.parse(json['date'] as String),
  vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
  driver: Driver.fromJson(json['driver'] as Map<String, dynamic>),
  helpers: (json['helpers'] as List<dynamic>)
      .map((e) => Helpers.fromJson(e as Map<String, dynamic>))
      .toList(),
  shift: json['shift'] == null
      ? null
      : Shift.fromJson(json['shift'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MyCrewToJson(MyCrew instance) => <String, dynamic>{
  'crew_id': instance.crewId,
  'date': instance.date.toIso8601String(),
  'vehicle': instance.vehicle,
  'driver': instance.driver,
  'helpers': instance.helpers,
  'shift': instance.shift,
};
