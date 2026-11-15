// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assign_order_vehicle_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignOrderVehicleData _$AssignOrderVehicleDataFromJson(
  Map<String, dynamic> json,
) => AssignOrderVehicleData(
  orderReference: json['order_reference'] as String,
  vehicleId: json['vehicle_id'] as String,
  plate: json['plate'] as String,
  shipments: (json['shipments'] as List<dynamic>)
      .map((e) => Shipments.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AssignOrderVehicleDataToJson(
  AssignOrderVehicleData instance,
) => <String, dynamic>{
  'order_reference': instance.orderReference,
  'vehicle_id': instance.vehicleId,
  'plate': instance.plate,
  'shipments': instance.shipments,
};
