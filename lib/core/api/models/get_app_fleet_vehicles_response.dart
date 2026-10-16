// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle.dart';
import 'collection_meta.dart';

part 'get_app_fleet_vehicles_response.g.dart';

@JsonSerializable()
class GetAppFleetVehiclesResponse {
  const GetAppFleetVehiclesResponse({this.data, this.meta});

  factory GetAppFleetVehiclesResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetVehiclesResponseFromJson(json);

  final List<Vehicle>? data;
  final CollectionMeta? meta;

  Map<String, Object?> toJson() => _$GetAppFleetVehiclesResponseToJson(this);
}
