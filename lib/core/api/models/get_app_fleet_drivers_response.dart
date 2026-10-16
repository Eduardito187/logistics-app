// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver.dart';
import 'collection_meta.dart';

part 'get_app_fleet_drivers_response.g.dart';

@JsonSerializable()
class GetAppFleetDriversResponse {
  const GetAppFleetDriversResponse({this.data, this.meta});

  factory GetAppFleetDriversResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetDriversResponseFromJson(json);

  final List<Driver>? data;
  final CollectionMeta? meta;

  Map<String, Object?> toJson() => _$GetAppFleetDriversResponseToJson(this);
}
