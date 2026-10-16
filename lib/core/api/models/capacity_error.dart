// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error2.dart';

part 'capacity_error.g.dart';

@JsonSerializable()
class CapacityError {
  const CapacityError({required this.error});

  factory CapacityError.fromJson(Map<String, Object?> json) =>
      _$CapacityErrorFromJson(json);

  final Error2 error;

  Map<String, Object?> toJson() => _$CapacityErrorToJson(this);
}
