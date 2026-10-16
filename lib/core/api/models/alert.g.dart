// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Alert _$AlertFromJson(Map<String, dynamic> json) => Alert(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  type: AlertType.fromJson(json['type'] as String),
  severity: AlertSeverity.fromJson(json['severity'] as String),
  detail: json['detail'],
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  driverId: json['driver_id'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  acknowledgedAt: json['acknowledged_at'] == null
      ? null
      : DateTime.parse(json['acknowledged_at'] as String),
  acknowledgedBy: json['acknowledged_by'] as String?,
);

Map<String, dynamic> _$AlertToJson(Alert instance) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'type': instance.type,
  'severity': instance.severity,
  'lat': instance.lat,
  'lng': instance.lng,
  'detail': instance.detail,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'acknowledged_at': instance.acknowledgedAt?.toIso8601String(),
  'acknowledged_by': instance.acknowledgedBy,
};
