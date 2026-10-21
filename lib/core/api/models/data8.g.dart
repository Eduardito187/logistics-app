// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data8.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data8 _$Data8FromJson(Map<String, dynamic> json) => Data8(
  eventId: json['event_id'] as String,
  shipmentRef: json['shipment_ref'] as String,
  status: Status3.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data8ToJson(Data8 instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'shipment_ref': instance.shipmentRef,
  'status': instance.status,
};
