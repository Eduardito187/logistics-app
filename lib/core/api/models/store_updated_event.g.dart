// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_updated_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreUpdatedEvent _$StoreUpdatedEventFromJson(Map<String, dynamic> json) =>
    StoreUpdatedEvent(
      nodeId: json['node_id'] as String,
      shipmentId: json['shipment_id'] as String?,
    );

Map<String, dynamic> _$StoreUpdatedEventToJson(StoreUpdatedEvent instance) =>
    <String, dynamic>{
      'node_id': instance.nodeId,
      'shipment_id': instance.shipmentId,
    };
