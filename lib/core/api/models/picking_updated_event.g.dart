// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'picking_updated_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PickingUpdatedEvent _$PickingUpdatedEventFromJson(Map<String, dynamic> json) =>
    PickingUpdatedEvent(
      shipmentId: json['shipment_id'] as String?,
      orderReference: json['order_reference'] as String?,
      planId: json['plan_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
    );

Map<String, dynamic> _$PickingUpdatedEventToJson(
  PickingUpdatedEvent instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'order_reference': instance.orderReference,
  'plan_id': instance.planId,
  'vehicle_id': instance.vehicleId,
};
