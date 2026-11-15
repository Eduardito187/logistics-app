// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Scope _$ScopeFromJson(Map<String, dynamic> json) => Scope(
  shipmentIds: (json['shipment_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  vehicleId: json['vehicle_id'] as String?,
  city: json['city'] as String?,
  routeDate: json['route_date'] == null
      ? null
      : DateTime.parse(json['route_date'] as String),
);

Map<String, dynamic> _$ScopeToJson(Scope instance) => <String, dynamic>{
  'shipment_ids': instance.shipmentIds,
  'vehicle_id': instance.vehicleId,
  'city': instance.city,
  'route_date': instance.routeDate?.toIso8601String(),
};
