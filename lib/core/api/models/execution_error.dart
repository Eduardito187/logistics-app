// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error5.dart';

part 'execution_error.g.dart';

@JsonSerializable()
class ExecutionError {
  const ExecutionError({required this.error});

  factory ExecutionError.fromJson(Map<String, Object?> json) =>
      _$ExecutionErrorFromJson(json);

  final Error5 error;

  Map<String, Object?> toJson() => _$ExecutionErrorToJson(this);
}
