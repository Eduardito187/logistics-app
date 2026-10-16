// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'emit_label_line.g.dart';

@JsonSerializable()
class EmitLabelLine {
  const EmitLabelLine({
    required this.sku,
    required this.name,
    required this.quantity,
    this.piecesPerUnit = 1,
  });

  factory EmitLabelLine.fromJson(Map<String, Object?> json) =>
      _$EmitLabelLineFromJson(json);

  final String sku;

  /// Nombre del producto; no viaja en el QR (ADR 004)
  final String name;

  /// Unidades del producto en la línea
  final int quantity;

  /// Piezas (cajas) por unidad; una etiqueta por pieza
  @JsonKey(name: 'pieces_per_unit')
  final int piecesPerUnit;

  Map<String, Object?> toJson() => _$EmitLabelLineToJson(this);
}
