// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_notification_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueueNotificationRequest _$QueueNotificationRequestFromJson(
  Map<String, dynamic> json,
) => QueueNotificationRequest(
  shipmentId: json['shipment_id'] as String,
  messageType: MessageType.fromJson(json['message_type'] as String),
  email: json['email'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$QueueNotificationRequestToJson(
  QueueNotificationRequest instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'message_type': instance.messageType,
  'email': instance.email,
  'phone': instance.phone,
};
