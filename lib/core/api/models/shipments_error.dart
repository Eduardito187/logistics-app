// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error9.dart';

part 'shipments_error.g.dart';

@JsonSerializable()
class ShipmentsError {
  const ShipmentsError({required this.error});

  factory ShipmentsError.fromJson(Map<String, Object?> json) =>
      _$ShipmentsErrorFromJson(json);

  final Error9 error;

  Map<String, Object?> toJson() => _$ShipmentsErrorToJson(this);
}
