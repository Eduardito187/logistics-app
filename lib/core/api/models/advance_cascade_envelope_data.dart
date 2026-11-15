// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'advance_cascade_envelope_data.g.dart';

@JsonSerializable()
class AdvanceCascadeEnvelopeData {
  const AdvanceCascadeEnvelopeData({
    required this.notificationId,
    required this.status,
  });

  factory AdvanceCascadeEnvelopeData.fromJson(Map<String, Object?> json) =>
      _$AdvanceCascadeEnvelopeDataFromJson(json);

  @JsonKey(name: 'notification_id')
  final String notificationId;
  final String status;

  Map<String, Object?> toJson() => _$AdvanceCascadeEnvelopeDataToJson(this);
}
