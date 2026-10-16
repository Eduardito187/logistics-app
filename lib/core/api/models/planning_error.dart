// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error7.dart';

part 'planning_error.g.dart';

@JsonSerializable()
class PlanningError {
  const PlanningError({required this.error});

  factory PlanningError.fromJson(Map<String, Object?> json) =>
      _$PlanningErrorFromJson(json);

  final Error7 error;

  Map<String, Object?> toJson() => _$PlanningErrorToJson(this);
}
