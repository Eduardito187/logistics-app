// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'maintenance_plan.dart';

part 'get_app_fleetops_maintenance_plans_response.g.dart';

@JsonSerializable()
class GetAppFleetopsMaintenancePlansResponse {
  const GetAppFleetopsMaintenancePlansResponse({required this.data});

  factory GetAppFleetopsMaintenancePlansResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsMaintenancePlansResponseFromJson(json);

  final List<MaintenancePlan> data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsMaintenancePlansResponseToJson(this);
}
