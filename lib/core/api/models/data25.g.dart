// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data25.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data25 _$Data25FromJson(Map<String, dynamic> json) => Data25(
  shipmentId: json['shipment_id'] as String,
  messageType: MessageType.fromJson(json['message_type'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$Data25ToJson(Data25 instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'message_type': instance.messageType,
  'status': instance.status,
};
