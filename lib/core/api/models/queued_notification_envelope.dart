// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data24.dart';

part 'queued_notification_envelope.g.dart';

@JsonSerializable()
class QueuedNotificationEnvelope {
  const QueuedNotificationEnvelope({required this.data});

  factory QueuedNotificationEnvelope.fromJson(Map<String, Object?> json) =>
      _$QueuedNotificationEnvelopeFromJson(json);

  final Data24 data;

  Map<String, Object?> toJson() => _$QueuedNotificationEnvelopeToJson(this);
}
