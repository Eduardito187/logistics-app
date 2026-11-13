// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'conduct_pre_trip_checklist_request.g.dart';

@JsonSerializable()
class ConductPreTripChecklistRequest {
  const ConductPreTripChecklistRequest({
    required this.vehicleId,
    required this.driverId,
    required this.items,
    required this.performedOn,
    this.notes,
    this.routeId,
  });

  factory ConductPreTripChecklistRequest.fromJson(Map<String, Object?> json) =>
      _$ConductPreTripChecklistRequestFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String driverId;
  final Map<String, bool> items;
  @JsonKey(name: 'performed_on')
  final DateTime performedOn;
  final String? notes;

  /// Ruta/viaje a la que se liga la inspección (UUID = `DriverRoute.id`).
  /// Opcional: habilita el checklist POR RUTA en el backend. (Campo aditivo
  /// agregado a mano; al regenerar el cliente viene solo.)
  @JsonKey(name: 'route_id')
  final String? routeId;

  Map<String, Object?> toJson() => _$ConductPreTripChecklistRequestToJson(this);
}
