// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'accepted_envelope_data.g.dart';

@JsonSerializable()
class AcceptedEnvelopeData {
  const AcceptedEnvelopeData({required this.accepted});

  factory AcceptedEnvelopeData.fromJson(Map<String, Object?> json) =>
      _$AcceptedEnvelopeDataFromJson(json);

  final bool accepted;

  Map<String, Object?> toJson() => _$AcceptedEnvelopeDataToJson(this);
}
