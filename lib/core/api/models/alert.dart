// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'alert_severity.dart';
import 'alert_type.dart';

part 'alert.g.dart';

/// Una alerta de mal uso de un vehículo.
@JsonSerializable()
class Alert {
  const Alert({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.severity,
    required this.detail,
    required this.occurredAt,
    this.driverId,
    this.lat,
    this.lng,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });

  factory Alert.fromJson(Map<String, Object?> json) => _$AlertFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  final AlertType type;
  final AlertSeverity severity;
  final double? lat;
  final double? lng;
  final dynamic detail;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  @JsonKey(name: 'acknowledged_at')
  final DateTime? acknowledgedAt;
  @JsonKey(name: 'acknowledged_by')
  final String? acknowledgedBy;

  Map<String, Object?> toJson() => _$AlertToJson(this);
}
