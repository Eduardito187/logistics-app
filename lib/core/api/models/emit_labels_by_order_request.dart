// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'emit_label_line.dart';

part 'emit_labels_by_order_request.g.dart';

/// Cuerpo OPCIONAL del POST de etiquetas por la app. Si se envía con `origin` + `destination` + `lines`, se emite ese lote explícito (igual que EmitLabelsRequest). Si se envía VACÍO (o solo con `origin` como escape hatch), el backend emite por ORDEN: deriva origen, destino y líneas de los envíos del pedido y del plan publicado, y emite solo las líneas AUTORIZADAS (con plan publicado) y aún PENDING. El valor de `origin` del QR lo fija el backend (no es contrato con la app); este campo solo lo impone cuando el integrador ya conoce el CD de origen.
@JsonSerializable()
class EmitLabelsByOrderRequest {
  const EmitLabelsByOrderRequest({this.origin, this.destination, this.lines});

  factory EmitLabelsByOrderRequest.fromJson(Map<String, Object?> json) =>
      _$EmitLabelsByOrderRequestFromJson(json);

  /// Nodo de origen (opcional; si se omite, el backend lo deriva por envío)
  final String? origin;

  /// Nodo de destino (opcional; requerido solo para el lote explícito)
  final String? destination;

  /// Líneas del lote explícito (opcional; si se omite, se derivan del pedido)
  final List<EmitLabelLine>? lines;

  Map<String, Object?> toJson() => _$EmitLabelsByOrderRequestToJson(this);
}
