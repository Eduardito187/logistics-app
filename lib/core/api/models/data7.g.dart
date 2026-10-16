// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data7.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data7 _$Data7FromJson(Map<String, dynamic> json) => Data7(
  eventId: json['event_id'] as String,
  shipmentRef: json['shipment_ref'] as String,
  status: Status2.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data7ToJson(Data7 instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'shipment_ref': instance.shipmentRef,
  'status': instance.status,
};
