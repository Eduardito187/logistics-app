// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'rename_device_request.g.dart';

@JsonSerializable()
class RenameDeviceRequest {
  const RenameDeviceRequest({required this.name});

  factory RenameDeviceRequest.fromJson(Map<String, Object?> json) =>
      _$RenameDeviceRequestFromJson(json);

  /// Custom name; null clears it.
  final String? name;

  Map<String, Object?> toJson() => _$RenameDeviceRequestToJson(this);
}
