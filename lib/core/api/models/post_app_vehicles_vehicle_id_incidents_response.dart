// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'post_app_vehicles_vehicle_id_incidents_response.g.dart';

@JsonSerializable()
class PostAppVehiclesVehicleIdIncidentsResponse {
  const PostAppVehiclesVehicleIdIncidentsResponse({this.data});

  factory PostAppVehiclesVehicleIdIncidentsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppVehiclesVehicleIdIncidentsResponseFromJson(json);

  /// The driver route after the incident — stops in order with their updated status and ETA.
  final dynamic data;

  Map<String, Object?> toJson() =>
      _$PostAppVehiclesVehicleIdIncidentsResponseToJson(this);
}
