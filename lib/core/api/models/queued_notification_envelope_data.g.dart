// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queued_notification_envelope_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueuedNotificationEnvelopeData _$QueuedNotificationEnvelopeDataFromJson(
  Map<String, dynamic> json,
) => QueuedNotificationEnvelopeData(
  shipmentId: json['shipment_id'] as String,
  messageType: MessageType.fromJson(json['message_type'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$QueuedNotificationEnvelopeDataToJson(
  QueuedNotificationEnvelopeData instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'message_type': instance.messageType,
  'status': instance.status,
};
