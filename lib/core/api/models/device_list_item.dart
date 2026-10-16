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
  });

  factory DeviceListItem.fromJson(Map<String, Object?> json) =>
      _$DeviceListItemFromJson(json);

  final String uuid;
  final String? platform;
  final String? name;
  @JsonKey(name: 'last_seen_at')
  final DateTime? lastSeenAt;
  final bool revoked;

  Map<String, Object?> toJson() => _$DeviceListItemToJson(this);
}
