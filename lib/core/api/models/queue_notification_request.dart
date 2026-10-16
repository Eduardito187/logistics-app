// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_type.dart';

part 'queue_notification_request.g.dart';

@JsonSerializable()
class QueueNotificationRequest {
  const QueueNotificationRequest({
    required this.shipmentId,
    required this.messageType,
    this.email,
    this.phone,
  });

  factory QueueNotificationRequest.fromJson(Map<String, Object?> json) =>
      _$QueueNotificationRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'message_type')
  final MessageType messageType;

  /// Optional email fallback for the cascade.
  final String? email;

  /// Optional phone fallback for the critical SMS step.
  final String? phone;

  Map<String, Object?> toJson() => _$QueueNotificationRequestToJson(this);
}
