// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_app_fleetops_maintenance_due_response.g.dart';

@JsonSerializable()
class GetAppFleetopsMaintenanceDueResponse {
  const GetAppFleetopsMaintenanceDueResponse({required this.data});

  factory GetAppFleetopsMaintenanceDueResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsMaintenanceDueResponseFromJson(json);

  final List<dynamic> data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsMaintenanceDueResponseToJson(this);
}
