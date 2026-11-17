// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'alerts_updated_event.g.dart';

/// Señal `alerts.updated` (tema operations): se levantó o reconoció una alerta de flota/telemetría. Señal para volver a pedir las alertas activas. Canales `private-operations.all` / `private-operations.city.<departamento>`.
@JsonSerializable()
class AlertsUpdatedEvent {
  const AlertsUpdatedEvent({this.alertId});

  factory AlertsUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$AlertsUpdatedEventFromJson(json);

  @JsonKey(name: 'alert_id')
  final String? alertId;

  Map<String, Object?> toJson() => _$AlertsUpdatedEventToJson(this);
}
