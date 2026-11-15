// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'piece2.dart';
import 'unit2.dart';

part 'label_unit_resolution.g.dart';

/// Resolución de una etiqueta escaneada (ULID) al producto físico + envío (fallback online).
@JsonSerializable()
class LabelUnitResolution {
  const LabelUnitResolution({
    required this.labelId,
    required this.resolved,
    required this.unitId,
    required this.shipmentId,
    required this.sku,
    required this.productName,
    required this.lineNumber,
    required this.unit,
    required this.piece,
    this.orderNumber,
    this.customerName,
    this.customerDocumentId,
    this.customerPhone,
    this.destinationNodeId,
  });

  factory LabelUnitResolution.fromJson(Map<String, Object?> json) =>
      _$LabelUnitResolutionFromJson(json);

  @JsonKey(name: 'label_id')
  final String labelId;
  final bool resolved;
  @JsonKey(name: 'unit_id')
  final String? unitId;
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  final String? sku;
  @JsonKey(name: 'product_name')
  final String? productName;
  @JsonKey(name: 'line_number')
  final int? lineNumber;
  final Unit2? unit;
  final Piece2? piece;
  @JsonKey(name: 'order_number')
  final String? orderNumber;

  /// Cliente del pedido de la etiqueta
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'customer_document_id')
  final String? customerDocumentId;
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;

  /// Tienda/nodo destino del envío (para saber si el pedido es de otra tienda)
  @JsonKey(name: 'destination_node_id')
  final String? destinationNodeId;

  Map<String, Object?> toJson() => _$LabelUnitResolutionToJson(this);
}
