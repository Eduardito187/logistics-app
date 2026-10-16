// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data24.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data24 _$Data24FromJson(Map<String, dynamic> json) => Data24(
  shipmentId: json['shipment_id'] as String,
  messageType: MessageType.fromJson(json['message_type'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$Data24ToJson(Data24 instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'message_type': instance.messageType,
  'status': instance.status,
};
