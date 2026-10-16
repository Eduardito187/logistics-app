// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pre_trip_checklist.g.dart';

@JsonSerializable()
class PreTripChecklist {
  const PreTripChecklist({
    this.id,
    this.vehicleId,
    this.driverId,
    this.items,
    this.passed,
    this.pending,
    this.performedOn,
    this.notes,
  });

  factory PreTripChecklist.fromJson(Map<String, Object?> json) =>
      _$PreTripChecklistFromJson(json);

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

  Map<String, Object?> toJson() => _$PreTripChecklistToJson(this);
}
