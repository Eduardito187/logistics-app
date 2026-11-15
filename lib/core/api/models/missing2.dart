// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'reason2.dart';

part 'missing2.g.dart';

@JsonSerializable()
class Missing2 {
  const Missing2({this.unitId, this.reason});

  factory Missing2.fromJson(Map<String, Object?> json) =>
      _$Missing2FromJson(json);

  @JsonKey(name: 'unit_id')
  final String? unitId;
  final Reason2? reason;

  Map<String, Object?> toJson() => _$Missing2ToJson(this);
}
