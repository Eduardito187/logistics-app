// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'channel.dart';
import 'message_type.dart';
import 'notification_status.dart';

part 'notification_view.g.dart';

/// Read model of a notification (flat primitives).
@JsonSerializable()
class NotificationView {
  const NotificationView({
    required this.id,
    required this.shipmentId,
    required this.messageType,
    required this.status,
    required this.currentChannel,
    required this.fcmTopic,
    required this.channels,
    required this.attempts,
    this.shipmentExternalId,
  });

  factory NotificationView.fromJson(Map<String, Object?> json) =>
      _$NotificationViewFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;

  /// Referencia externa humana del envío (shipments.external_id); null si no hay envío asociado
  @JsonKey(name: 'shipment_external_id')
  final String? shipmentExternalId;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final NotificationStatus status;
  @JsonKey(name: 'current_channel')
  final Channel currentChannel;

  /// Firebase Cloud Messaging topic of the shipment (shipment_<id>); the app subscribes to it.
  @JsonKey(name: 'fcm_topic')
  final String fcmTopic;

  /// Policy channels, in cascade order.
  final List<Channel> channels;

  /// Attempts per channel.
  final Map<String, int> attempts;

  Map<String, Object?> toJson() => _$NotificationViewToJson(this);
}
