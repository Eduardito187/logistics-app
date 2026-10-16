// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'maintenance_order.dart';

part 'get_app_fleetops_maintenance_orders_order_id_response.g.dart';

@JsonSerializable()
class GetAppFleetopsMaintenanceOrdersOrderIdResponse {
  const GetAppFleetopsMaintenanceOrdersOrderIdResponse({required this.data});

  factory GetAppFleetopsMaintenanceOrdersOrderIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsMaintenanceOrdersOrderIdResponseFromJson(json);

  final MaintenanceOrder data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsMaintenanceOrdersOrderIdResponseToJson(this);
}
