// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'failed_by_reason.g.dart';

@JsonSerializable()
class FailedByReason {
  const FailedByReason({required this.reason, required this.count});

  factory FailedByReason.fromJson(Map<String, Object?> json) =>
      _$FailedByReasonFromJson(json);

  final String reason;
  final int count;

  Map<String, Object?> toJson() => _$FailedByReasonToJson(this);
}
