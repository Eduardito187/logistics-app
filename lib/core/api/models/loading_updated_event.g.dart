// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loading_updated_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoadingUpdatedEvent _$LoadingUpdatedEventFromJson(Map<String, dynamic> json) =>
    LoadingUpdatedEvent(
      vehicleId: json['vehicle_id'] as String,
      shipmentId: json['shipment_id'] as String?,
    );

Map<String, dynamic> _$LoadingUpdatedEventToJson(
  LoadingUpdatedEvent instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'shipment_id': instance.shipmentId,
};
