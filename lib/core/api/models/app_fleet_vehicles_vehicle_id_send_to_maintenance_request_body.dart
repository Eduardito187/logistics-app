// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'type.dart';

part 'app_fleet_vehicles_vehicle_id_send_to_maintenance_request_body.g.dart';

@JsonSerializable()
class AppFleetVehiclesVehicleIdSendToMaintenanceRequestBody {
  const AppFleetVehiclesVehicleIdSendToMaintenanceRequestBody({
    this.workshop,
    this.note,
    this.odometerKm,
    this.scheduledAt,
    this.reassignToVehicleId,
    this.type = Type.corrective,
  });

  factory AppFleetVehiclesVehicleIdSendToMaintenanceRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppFleetVehiclesVehicleIdSendToMaintenanceRequestBodyFromJson(json);

  final Type type;
  final String? workshop;
  final String? note;
  @JsonKey(name: 'odometer_km')
  final int? odometerKm;

  /// Por defecto, ahora
  @JsonKey(name: 'scheduled_at')
  final DateTime? scheduledAt;

  /// Camión que toma las paradas pendientes de la ruta. Si se omite, esas paradas se liberan y quedan por asignar.
  @JsonKey(name: 'reassign_to_vehicle_id')
  final String? reassignToVehicleId;

  Map<String, Object?> toJson() =>
      _$AppFleetVehiclesVehicleIdSendToMaintenanceRequestBodyToJson(this);
}
