// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'due_maintenance_item.dart';
import 'list_meta.dart';

part 'get_app_fleetops_maintenance_due_response.g.dart';

@JsonSerializable()
class GetAppFleetopsMaintenanceDueResponse {
  const GetAppFleetopsMaintenanceDueResponse({required this.data, this.meta});

  factory GetAppFleetopsMaintenanceDueResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsMaintenanceDueResponseFromJson(json);

  final List<DueMaintenanceItem> data;

  /// Present only when pagination parameters are sent.
  final ListMeta? meta;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsMaintenanceDueResponseToJson(this);
}
