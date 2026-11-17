// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fleet_removed_event.g.dart';

/// Carga del evento `fleet.removed` (tema fleet): el vehículo se dio de baja en flota; quitarlo de la lista por id.
@JsonSerializable()
class FleetRemovedEvent {
  const FleetRemovedEvent({required this.vehicleId});

  factory FleetRemovedEvent.fromJson(Map<String, Object?> json) =>
      _$FleetRemovedEventFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;

  Map<String, Object?> toJson() => _$FleetRemovedEventToJson(this);
}
