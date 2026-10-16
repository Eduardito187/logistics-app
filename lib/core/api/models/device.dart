// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

@JsonSerializable()
class Device {
  const Device({
    required this.fingerprint,
    this.platform,
    this.name,
    this.pushToken,
  });

  factory Device.fromJson(Map<String, Object?> json) => _$DeviceFromJson(json);

  final String fingerprint;
  final String? platform;
  final String? name;
  @JsonKey(name: 'push_token')
  final String? pushToken;

  Map<String, Object?> toJson() => _$DeviceToJson(this);
}
