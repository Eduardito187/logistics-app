// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'maintenance_order.dart';

part 'get_app_fleetops_maintenance_orders_response.g.dart';

@JsonSerializable()
class GetAppFleetopsMaintenanceOrdersResponse {
  const GetAppFleetopsMaintenanceOrdersResponse({required this.data});

  factory GetAppFleetopsMaintenanceOrdersResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsMaintenanceOrdersResponseFromJson(json);

  final List<MaintenanceOrder> data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsMaintenanceOrdersResponseToJson(this);
}
