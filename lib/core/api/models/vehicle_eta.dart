// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lat_lng_point.dart';
import 'position.dart';
import 'stops2.dart';

part 'vehicle_eta.g.dart';

/// Dynamic ETA from the latest position. No live traffic source exists (traffic_aware is always false).
@JsonSerializable()
class VehicleEta {
  const VehicleEta({
    this.offRoute,
    this.offRouteSince,
    this.rerouteGeometry,
    this.shipmentId,
    this.vehicleId,
    this.plate,
    this.trafficAware,
    this.position,
    this.positionStale,
    this.generatedAt,
    this.stops,
  });

  factory VehicleEta.fromJson(Map<String, Object?> json) =>
      _$VehicleEtaFromJson(json);

  @JsonKey(name: 'off_route')
  final bool? offRoute;
  @JsonKey(name: 'off_route_since')
  final DateTime? offRouteSince;

  /// Polilínea (posición actual → próxima parada pendiente) para redibujar la ruta cuando el vehículo está fuera de ruta. null salvo off_route=true.
  @JsonKey(name: 'reroute_geometry')
  final List<LatLngPoint>? rerouteGeometry;

  /// Only in the per-shipment endpoint
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  final String? plate;
  @JsonKey(name: 'traffic_aware')
  final bool? trafficAware;
  final Position? position;
  @JsonKey(name: 'position_stale')
  final bool? positionStale;
  @JsonKey(name: 'generated_at')
  final DateTime? generatedAt;
  final List<Stops2>? stops;

  Map<String, Object?> toJson() => _$VehicleEtaToJson(this);
}
