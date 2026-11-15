// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device_list_item.dart';

part 'patch_app_devices_uuid_response.g.dart';

@JsonSerializable()
class PatchAppDevicesUuidResponse {
  const PatchAppDevicesUuidResponse({required this.data});

  factory PatchAppDevicesUuidResponse.fromJson(Map<String, Object?> json) =>
      _$PatchAppDevicesUuidResponseFromJson(json);

  final DeviceListItem data;

  Map<String, Object?> toJson() => _$PatchAppDevicesUuidResponseToJson(this);
}
