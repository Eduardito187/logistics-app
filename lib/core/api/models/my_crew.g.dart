// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_crew.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyCrew _$MyCrewFromJson(Map<String, dynamic> json) => MyCrew(
  crewId: json['crew_id'] as String,
  date: DateTime.parse(json['date'] as String),
  vehicle: CrewVehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
  driver: CrewDriver.fromJson(json['driver'] as Map<String, dynamic>),
  helpers: (json['helpers'] as List<dynamic>)
      .map((e) => Helpers2.fromJson(e as Map<String, dynamic>))
      .toList(),
  shift: json['shift'] == null
      ? null
      : Shift.fromJson(json['shift'] as Map<String, dynamic>),
  routeId: json['route_id'] as String?,
  routeStatus: json['route_status'] == null
      ? null
      : DriverRouteStatus.fromJson(json['route_status'] as String),
);

Map<String, dynamic> _$MyCrewToJson(MyCrew instance) => <String, dynamic>{
  'crew_id': instance.crewId,
  'date': instance.date.toIso8601String(),
  'vehicle': instance.vehicle,
  'driver': instance.driver,
  'helpers': instance.helpers,
  'shift': instance.shift,
  'route_id': instance.routeId,
  'route_status': instance.routeStatus,
};
