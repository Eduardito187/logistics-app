// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'plans_updated_event.g.dart';

/// Carga del evento `plans.updated` (tema planning): se creó, editó (paradas u orden), publicó o borró un plan de ese día. Solo es la señal para volver a pedir la lista o el detalle.
@JsonSerializable()
class PlansUpdatedEvent {
  const PlansUpdatedEvent({
    required this.planDate,
    required this.deleted,
    required this.planId,
  });

  factory PlansUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$PlansUpdatedEventFromJson(json);

  @JsonKey(name: 'plan_date')
  final DateTime planDate;

  /// true cuando ese plan_id se borró (sacarlo de la lista y cerrar su detalle, sin volver a pedirlo); false en cualquier otro cambio.
  final bool deleted;

  /// null cuando cambiaron varios planes del día a la vez (mover un pedido entre camiones, corrida automática).
  @JsonKey(name: 'plan_id')
  final String? planId;

  Map<String, Object?> toJson() => _$PlansUpdatedEventToJson(this);
}
