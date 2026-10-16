// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'maintenance_item.dart';

part 'complete_maintenance_request.g.dart';

@JsonSerializable()
class CompleteMaintenanceRequest {
  const CompleteMaintenanceRequest({
    required this.items,
    required this.currency,
  });

  factory CompleteMaintenanceRequest.fromJson(Map<String, Object?> json) =>
      _$CompleteMaintenanceRequestFromJson(json);

  final List<MaintenanceItem> items;
  final String currency;

  Map<String, Object?> toJson() => _$CompleteMaintenanceRequestToJson(this);
}
