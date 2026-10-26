// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'qc_outcome.dart';

part 'lines2.g.dart';

@JsonSerializable()
class Lines2 {
  const Lines2({
    required this.sku,
    required this.accepted,
    required this.rejected,
    required this.damaged,
    required this.qcOutcome,
  });

  factory Lines2.fromJson(Map<String, Object?> json) => _$Lines2FromJson(json);

  final String sku;
  final int accepted;
  final int rejected;
  final int damaged;
  @JsonKey(name: 'qc_outcome')
  final QcOutcome qcOutcome;

  Map<String, Object?> toJson() => _$Lines2ToJson(this);
}
