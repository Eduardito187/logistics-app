// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error3.dart';

part 'coverage_error.g.dart';

@JsonSerializable()
class CoverageError {
  const CoverageError({required this.error});

  factory CoverageError.fromJson(Map<String, Object?> json) =>
      _$CoverageErrorFromJson(json);

  final Error3 error;

  Map<String, Object?> toJson() => _$CoverageErrorToJson(this);
}
