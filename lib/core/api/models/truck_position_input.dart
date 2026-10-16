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
  });

  factory TruckPositionInput.fromJson(Map<String, Object?> json) =>
      _$TruckPositionInputFromJson(json);

  final double lat;
  final double lng;

  /// Instante del reporte en ISO 8601
  @JsonKey(name: 'reported_at')
  final DateTime reportedAt;

  Map<String, Object?> toJson() => _$TruckPositionInputToJson(this);
}
