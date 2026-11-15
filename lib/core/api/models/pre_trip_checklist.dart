// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pre_trip_checklist.g.dart';

@JsonSerializable()
class PreTripChecklist {
  const PreTripChecklist({
    this.fitToDispatch,
    this.failedCritical,
    this.missingCritical,
    this.checklistTemplateId,
    this.id,
    this.vehicleId,
    this.driverId,
    this.items,
    this.passed,
    this.pending,
    this.performedOn,
    this.notes,
    this.routeId,
    this.plate,
    this.driverName,
  });

  factory PreTripChecklist.fromJson(Map<String, Object?> json) =>
      _$PreTripChecklistFromJson(json);

  @JsonKey(name: 'fit_to_dispatch')
  final bool? fitToDispatch;
  @JsonKey(name: 'failed_critical')
  final List<String>? failedCritical;
  @JsonKey(name: 'missing_critical')
  final List<String>? missingCritical;
  @JsonKey(name: 'checklist_template_id')
  final String? checklistTemplateId;
  final String? id;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;

  /// Map of checklist item name to its verification state.
  final Map<String, bool>? items;

  /// True only when every item is verified (fit to dispatch).
  final bool? passed;
  final List<String>? pending;
  @JsonKey(name: 'performed_on')
  final DateTime? performedOn;
  final String? notes;

  /// Route/trip this inspection belongs to (pre-trip check is per route, not per day).
  @JsonKey(name: 'route_id')
  final String? routeId;

  /// Plate of the inspected vehicle (null if the vehicle was removed from the fleet).
  final String? plate;

  /// Name of the driver who performed the inspection (null if removed from the fleet).
  @JsonKey(name: 'driver_name')
  final String? driverName;

  Map<String, Object?> toJson() => _$PreTripChecklistToJson(this);
}
