// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_view.dart';

part 'notification_list_envelope.g.dart';

@JsonSerializable()
class NotificationListEnvelope {
  const NotificationListEnvelope({required this.data});

  factory NotificationListEnvelope.fromJson(Map<String, Object?> json) =>
      _$NotificationListEnvelopeFromJson(json);

  final List<NotificationView> data;

  Map<String, Object?> toJson() => _$NotificationListEnvelopeToJson(this);
}
