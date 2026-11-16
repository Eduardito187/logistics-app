// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_updated_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackingUpdatedEvent _$TrackingUpdatedEventFromJson(
  Map<String, dynamic> json,
) => TrackingUpdatedEvent(
  shipmentId: json['shipment_id'] as String,
  status: TrackingUpdatedEventStatus.fromJson(json['status'] as String),
  event: json['event'] as String,
  orderReference: json['order_reference'] as String?,
);

Map<String, dynamic> _$TrackingUpdatedEventToJson(
  TrackingUpdatedEvent instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'order_reference': instance.orderReference,
  'status': instance.status,
  'event': instance.event,
};
