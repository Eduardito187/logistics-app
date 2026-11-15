// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'devices.g.dart';

@JsonSerializable()
class Devices {
  const Devices({
    this.id,
    this.name,
    this.platform,
    this.model,
    this.osVersion,
    this.appVersion,
    this.sessionBucket,
    this.lastSeenAt,
    this.revoked,
  });

  factory Devices.fromJson(Map<String, Object?> json) =>
      _$DevicesFromJson(json);

  final String? id;
  final String? name;
  final String? platform;
  final String? model;
  @JsonKey(name: 'os_version')
  final String? osVersion;
  @JsonKey(name: 'app_version')
  final String? appVersion;
  @JsonKey(name: 'session_bucket')
  final String? sessionBucket;
  @JsonKey(name: 'last_seen_at')
  final DateTime? lastSeenAt;
  final bool? revoked;

  Map<String, Object?> toJson() => _$DevicesToJson(this);
}
