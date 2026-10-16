// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'truck_position.g.dart';

/// Última posición conocida del camión
@JsonSerializable()
class TruckPosition {
  const TruckPosition({
    required this.lat,
    required this.lng,
    required this.reportedAt,
  });

  factory TruckPosition.fromJson(Map<String, Object?> json) =>
      _$TruckPositionFromJson(json);

  final double lat;
  final double lng;

  /// Instante del reporte en ISO 8601
  @JsonKey(name: 'reported_at')
  final DateTime reportedAt;

  Map<String, Object?> toJson() => _$TruckPositionToJson(this);
}
