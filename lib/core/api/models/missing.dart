// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'missing_unit_reason.dart';

part 'missing.g.dart';

@JsonSerializable()
class Missing {
  const Missing({required this.unitId, required this.reason});

  factory Missing.fromJson(Map<String, Object?> json) =>
      _$MissingFromJson(json);

  @JsonKey(name: 'unit_id')
  final String unitId;
  final MissingUnitReason reason;

  Map<String, Object?> toJson() => _$MissingToJson(this);
}
