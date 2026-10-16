// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device_list_item.dart';

part 'get_app_devices_response.g.dart';

@JsonSerializable()
class GetAppDevicesResponse {
  const GetAppDevicesResponse({required this.data});

  factory GetAppDevicesResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppDevicesResponseFromJson(json);

  final List<DeviceListItem> data;

  Map<String, Object?> toJson() => _$GetAppDevicesResponseToJson(this);
}
