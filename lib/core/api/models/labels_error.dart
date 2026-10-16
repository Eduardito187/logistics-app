// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error6.dart';

part 'labels_error.g.dart';

@JsonSerializable()
class LabelsError {
  const LabelsError({required this.error});

  factory LabelsError.fromJson(Map<String, Object?> json) =>
      _$LabelsErrorFromJson(json);

  final Error6 error;

  Map<String, Object?> toJson() => _$LabelsErrorToJson(this);
}
