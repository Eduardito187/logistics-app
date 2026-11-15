// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assign_shipment_to_plan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignShipmentToPlanRequest _$AssignShipmentToPlanRequestFromJson(
  Map<String, dynamic> json,
) => AssignShipmentToPlanRequest(
  shipmentId: json['shipment_id'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AssignShipmentToPlanRequestToJson(
  AssignShipmentToPlanRequest instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
