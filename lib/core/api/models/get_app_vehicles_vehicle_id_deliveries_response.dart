// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery.dart';
import 'meta5.dart';

part 'get_app_vehicles_vehicle_id_deliveries_response.g.dart';

@JsonSerializable()
class GetAppVehiclesVehicleIdDeliveriesResponse {
  const GetAppVehiclesVehicleIdDeliveriesResponse({
    required this.data,
    required this.meta,
  });

  factory GetAppVehiclesVehicleIdDeliveriesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppVehiclesVehicleIdDeliveriesResponseFromJson(json);

  final List<Delivery> data;
  final Meta5 meta;

  Map<String, Object?> toJson() =>
      _$GetAppVehiclesVehicleIdDeliveriesResponseToJson(this);
}
