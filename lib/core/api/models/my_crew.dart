// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver.dart';
import 'helpers.dart';
import 'shift.dart';
import 'vehicle.dart';

part 'my_crew.g.dart';

/// The crew (driver + helpers) and vehicle assigned to the authenticated driver for a date. Read-only projection returned by fleetGetMyCrew.
@JsonSerializable()
class MyCrew {
  const MyCrew({
    required this.crewId,
    required this.date,
    required this.vehicle,
    required this.driver,
    required this.helpers,
    required this.shift,
  });

  factory MyCrew.fromJson(Map<String, Object?> json) => _$MyCrewFromJson(json);

  @JsonKey(name: 'crew_id')
  final String crewId;
  final DateTime date;

  /// Assigned vehicle. `id` is always present; the other fields are null when the vehicle master record cannot be resolved.
  final Vehicle vehicle;

  /// The driver leading the crew. `name`/`license_number` are null when the driver record is missing.
  final Driver driver;
  final List<Helpers> helpers;

  /// Work-shift hours, or null when the crew was assembled without fixed hours.
  final Shift? shift;

  Map<String, Object?> toJson() => _$MyCrewToJson(this);
}
