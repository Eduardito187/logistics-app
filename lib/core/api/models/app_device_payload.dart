// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_device_payload.g.dart';

@JsonSerializable()
class AppDevicePayload {
  const AppDevicePayload({
    required this.uuid,
    required this.platform,
    required this.name,
    required this.lastSeenAt,
  });

  factory AppDevicePayload.fromJson(Map<String, Object?> json) =>
      _$AppDevicePayloadFromJson(json);

  final String uuid;
  final String? platform;
  final String? name;
  @JsonKey(name: 'last_seen_at')
  final DateTime? lastSeenAt;

  Map<String, Object?> toJson() => _$AppDevicePayloadToJson(this);
}
