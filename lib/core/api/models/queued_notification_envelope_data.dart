// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_type.dart';

part 'queued_notification_envelope_data.g.dart';

@JsonSerializable()
class QueuedNotificationEnvelopeData {
  const QueuedNotificationEnvelopeData({
    required this.shipmentId,
    required this.messageType,
    required this.status,
  });

  factory QueuedNotificationEnvelopeData.fromJson(Map<String, Object?> json) =>
      _$QueuedNotificationEnvelopeDataFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final String status;

  Map<String, Object?> toJson() => _$QueuedNotificationEnvelopeDataToJson(this);
}
