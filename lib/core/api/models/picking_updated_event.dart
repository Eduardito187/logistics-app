// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'picking_updated_event.g.dart';

/// Señal `picking.updated` (tema picking): cambió la lista de preparación de una ciudad (plan publicado/modificado, pedido nuevo o que salió de la lista, camión asignado, escaneo de preparación, etiquetas emitidas/reimpresas). Señal para volver a pedir la lista. Canales `private-picking.all` / `private-picking.city.<departamento>`. shipment_id null = cambió la lista en general.
@JsonSerializable()
class PickingUpdatedEvent {
  const PickingUpdatedEvent({
    this.shipmentId,
    this.orderReference,
    this.planId,
    this.vehicleId,
  });

  factory PickingUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$PickingUpdatedEventFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String? shipmentId;

  /// Referencia del pedido (null si no hay una utilizable).
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'plan_id')
  final String? planId;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;

  Map<String, Object?> toJson() => _$PickingUpdatedEventToJson(this);
}
