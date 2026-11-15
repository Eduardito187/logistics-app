// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'device_list_item.g.dart';

@JsonSerializable()
class DeviceListItem {
  const DeviceListItem({
    required this.uuid,
    required this.platform,
    required this.name,
    required this.lastSeenAt,
    required this.revoked,
    this.displayName,
    this.model,
    this.osVersion,
    this.appVersion,
    this.appBuild,
    this.lastIp,
    this.isCurrent,
  });

  factory DeviceListItem.fromJson(Map<String, Object?> json) =>
      _$DeviceListItemFromJson(json);

  final String uuid;
  final String? platform;
  final String? name;
  @JsonKey(name: 'last_seen_at')
  final DateTime? lastSeenAt;
  final bool revoked;

  /// Name set by the owner, else the device model, else a generic platform name.
  @JsonKey(name: 'display_name')
  final String? displayName;
  final String? model;
  @JsonKey(name: 'os_version')
  final String? osVersion;
  @JsonKey(name: 'app_version')
  final String? appVersion;
  @JsonKey(name: 'app_build')
  final String? appBuild;

  /// Last client IP (IPv4 or IPv6) seen by the app gate, refreshed at most once per minute with last_seen_at. Only returned for the caller's own devices; null if never seen. Informational only.
  @JsonKey(name: 'last_ip')
  final String? lastIp;

  /// True for the device of the token making the request.
  @JsonKey(name: 'is_current')
  final bool? isCurrent;

  Map<String, Object?> toJson() => _$DeviceListItemToJson(this);
}
