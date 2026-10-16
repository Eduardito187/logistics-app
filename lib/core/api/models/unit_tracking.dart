// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'unit_status.dart';

part 'unit_tracking.g.dart';

/// Vista interna del seguimiento de un bulto
@JsonSerializable()
class UnitTracking {
  const UnitTracking({
    required this.id,
    required this.unitId,
    required this.shipmentId,
    required this.status,
    required this.lastLocationId,
    required this.lastSeenAt,
    required this.label,
  });

  factory UnitTracking.fromJson(Map<String, Object?> json) =>
      _$UnitTrackingFromJson(json);

  final String id;
  @JsonKey(name: 'unit_id')
  final String unitId;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final UnitStatus status;

  /// Nodo/parada donde se vio por última vez el bulto
  @JsonKey(name: 'last_location_id')
  final String? lastLocationId;
  @JsonKey(name: 'last_seen_at')
  final DateTime? lastSeenAt;

  /// Etiqueta humana del bulto ("N/M")
  final String? label;

  Map<String, Object?> toJson() => _$UnitTrackingToJson(this);
}
