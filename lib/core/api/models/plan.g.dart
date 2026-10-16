// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
  id: json['id'] as String,
  planDate: DateTime.parse(json['plan_date'] as String),
  vehicleId: json['vehicle_id'] as String,
  status: PlanStatus.fromJson(json['status'] as String),
  stops: (json['stops'] as List<dynamic>)
      .map((e) => PlannedStop.fromJson(e as Map<String, dynamic>))
      .toList(),
  routeGeometry: json['route_geometry'] == null
      ? null
      : RouteGeometry.fromJson(json['route_geometry'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  'id': instance.id,
  'plan_date': instance.planDate.toIso8601String(),
  'vehicle_id': instance.vehicleId,
  'status': instance.status,
  'stops': instance.stops,
  'route_geometry': instance.routeGeometry,
};
