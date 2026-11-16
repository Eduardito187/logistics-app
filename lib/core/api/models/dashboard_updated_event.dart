// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dashboard_updated_event.g.dart';

/// Señal `dashboard.updated` (tema operations): cambió una métrica del tablero del día (entrega registrada/fallida, ruta iniciada/cerrada, avance de carga). Señal para recalcular el tablero. Canales `private-operations.all` (+ `private-operations.city.<departamento>` si se resuelve la ciudad).
@JsonSerializable()
class DashboardUpdatedEvent {
  const DashboardUpdatedEvent({required this.planDate});

  factory DashboardUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$DashboardUpdatedEventFromJson(json);

  @JsonKey(name: 'plan_date')
  final DateTime planDate;

  Map<String, Object?> toJson() => _$DashboardUpdatedEventToJson(this);
}
