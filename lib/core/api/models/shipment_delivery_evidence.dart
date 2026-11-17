// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shipment_delivery_evidence.g.dart';

/// Qué evidencia quedó de la entrega de un envío ENTREGADO. Sin evidencia, los tres indicadores van en false.
@JsonSerializable()
class ShipmentDeliveryEvidence {
  const ShipmentDeliveryEvidence({
    required this.signature,
    required this.photo,
    required this.document,
    required this.withShortage,
    this.missingCount,
  });

  factory ShipmentDeliveryEvidence.fromJson(Map<String, Object?> json) =>
      _$ShipmentDeliveryEvidenceFromJson(json);

  /// Hay una firma del cliente capturada (evidencia de tipo signature).
  final bool signature;

  /// Hay al menos una foto de la entrega (evidencia de tipo pod o foto ligada a la prueba de entrega).
  final bool photo;

  /// Hay una foto del documento de identidad del cliente (evidencia de tipo id_document).
  final bool document;

  /// El envío entregado se cerró con faltante (traspaso conciliado con diferencias o cerrado a mano por oficina). false en entregas normales.
  @JsonKey(name: 'with_shortage')
  final bool withShortage;

  /// Cuántos productos faltaron (para el tag «Entregado con faltante (N)»). null si no hubo faltante o no se conoce la cantidad; el detalle se ve por el reporte de discrepancias.
  @JsonKey(name: 'missing_count')
  final int? missingCount;

  Map<String, Object?> toJson() => _$ShipmentDeliveryEvidenceToJson(this);
}
