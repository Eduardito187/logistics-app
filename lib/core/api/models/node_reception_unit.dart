// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'node_reception_unit.g.dart';

/// Producto de una recepción en nodo (foto, nombre, SKU) y su posición "N de M"
@JsonSerializable()
class NodeReceptionUnit {
  const NodeReceptionUnit({
    required this.unitId,
    required this.sku,
    required this.productName,
    required this.productImageUrl,
    required this.unitIndex,
    required this.unitTotal,
    required this.pieceIndex,
    required this.pieceTotal,
    this.location,
    this.locatedAt,
  });

  factory NodeReceptionUnit.fromJson(Map<String, Object?> json) =>
      _$NodeReceptionUnitFromJson(json);

  /// Shelf location at the node (e.g. A-03-2).
  final String? location;
  @JsonKey(name: 'located_at')
  final DateTime? locatedAt;
  @JsonKey(name: 'unit_id')
  final String unitId;
  final String? sku;
  @JsonKey(name: 'product_name')
  final String? productName;
  @JsonKey(name: 'product_image_url')
  final String? productImageUrl;
  @JsonKey(name: 'unit_index')
  final int? unitIndex;
  @JsonKey(name: 'unit_total')
  final int? unitTotal;
  @JsonKey(name: 'piece_index')
  final int? pieceIndex;
  @JsonKey(name: 'piece_total')
  final int? pieceTotal;

  Map<String, Object?> toJson() => _$NodeReceptionUnitToJson(this);
}
