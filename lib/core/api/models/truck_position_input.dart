// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'truck_position_input.g.dart';

@JsonSerializable()
class TruckPositionInput {
  const TruckPositionInput({
    required this.lat,
    required this.lng,
    required this.reportedAt,
    this.speedMps,
    this.headingDeg,
    this.accuracyM,
  });

  factory TruckPositionInput.fromJson(Map<String, Object?> json) =>
      _$TruckPositionInputFromJson(json);

  final double lat;
  final double lng;

  /// Instante del reporte en ISO 8601
  @JsonKey(name: 'reported_at')
  final DateTime reportedAt;

  /// Velocidad instantánea en m/s. Opcional; si falta, el backend la deriva de dos posiciones seguidas.
  @JsonKey(name: 'speed_mps')
  final double? speedMps;

  /// Rumbo en grados desde el norte (0..360). Opcional; si falta, se deriva del desplazamiento.
  @JsonKey(name: 'heading_deg')
  final double? headingDeg;

  /// Precisión horizontal del GPS en metros. Opcional.
  @JsonKey(name: 'accuracy_m')
  final double? accuracyM;

  Map<String, Object?> toJson() => _$TruckPositionInputToJson(this);
}
