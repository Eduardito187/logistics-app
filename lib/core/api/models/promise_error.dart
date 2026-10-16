// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error8.dart';

part 'promise_error.g.dart';

@JsonSerializable()
class PromiseError {
  const PromiseError({required this.error});

  factory PromiseError.fromJson(Map<String, Object?> json) =>
      _$PromiseErrorFromJson(json);

  final Error8 error;

  Map<String, Object?> toJson() => _$PromiseErrorToJson(this);
}
