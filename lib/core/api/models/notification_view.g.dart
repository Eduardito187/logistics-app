// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationView _$NotificationViewFromJson(Map<String, dynamic> json) =>
    NotificationView(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      messageType: MessageType.fromJson(json['message_type'] as String),
      status: NotificationStatus.fromJson(json['status'] as String),
      currentChannel: Channel.fromJson(json['current_channel'] as String),
      fcmTopic: json['fcm_topic'] as String,
      channels: (json['channels'] as List<dynamic>)
          .map((e) => Channel.fromJson(e as String))
          .toList(),
      attempts: Map<String, int>.from(json['attempts'] as Map),
      shipmentExternalId: json['shipment_external_id'] as String?,
    );

Map<String, dynamic> _$NotificationViewToJson(NotificationView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shipment_id': instance.shipmentId,
      'shipment_external_id': instance.shipmentExternalId,
      'message_type': instance.messageType,
      'status': instance.status,
      'current_channel': instance.currentChannel,
      'fcm_topic': instance.fcmTopic,
      'channels': instance.channels,
      'attempts': instance.attempts,
    };
