// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'trip_sequence_warning_code.dart';

part 'trip_sequence_warning.g.dart';

@JsonSerializable()
class TripSequenceWarning {
  const TripSequenceWarning({
    required this.code,
    required this.shipmentId,
    required this.detail,
  });

  factory TripSequenceWarning.fromJson(Map<String, Object?> json) =>
      _$TripSequenceWarningFromJson(json);

  final TripSequenceWarningCode code;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;

  /// Human-readable explanation (Spanish), with no internal identifiers.
  final String detail;

  Map<String, Object?> toJson() => _$TripSequenceWarningToJson(this);
}
