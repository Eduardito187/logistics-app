// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fleet_assemble_crew_data_outcome.dart';
import 'helpers2.dart';

part 'fleet_assemble_crew_data.g.dart';

@JsonSerializable()
class FleetAssembleCrewData {
  const FleetAssembleCrewData({
    this.status,
    this.outcome,
    this.driverId,
    this.vehicleId,
    this.assembledFor,
    this.crewId,
    this.vehiclePlate,
    this.previousVehiclePlate,
    this.helpers,
  });

  factory FleetAssembleCrewData.fromJson(Map<String, Object?> json) =>
      _$FleetAssembleCrewDataFromJson(json);

  final String? status;

  /// created = tripulación nueva; replaced = reemplazó a la anterior (camión cambiado); unchanged = ya estaba igual (idempotente).
  final FleetAssembleCrewDataOutcome? outcome;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'assembled_for')
  final DateTime? assembledFor;
  @JsonKey(name: 'crew_id')
  final String? crewId;
  @JsonKey(name: 'vehicle_plate')
  final String? vehiclePlate;

  /// Placa del camión que tenía antes, cuando outcome = replaced.
  @JsonKey(name: 'previous_vehicle_plate')
  final String? previousVehiclePlate;
  final List<Helpers2>? helpers;

  Map<String, Object?> toJson() => _$FleetAssembleCrewDataToJson(this);
}
