// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'carrier_assignment_unit.g.dart';

@JsonSerializable()
class CarrierAssignmentUnit {
  const CarrierAssignmentUnit({
    required this.unitId,
    required this.sku,
    required this.productName,
    required this.productLabel,
    required this.pieceIndex,
    required this.pieceTotal,
  });

  factory CarrierAssignmentUnit.fromJson(Map<String, Object?> json) =>
      _$CarrierAssignmentUnitFromJson(json);

  @JsonKey(name: 'unit_id')
  final String unitId;
  final String sku;

  /// Nunca vacío (fallback SKU o "Producto").
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'product_label')
  final String productLabel;
  @JsonKey(name: 'piece_index')
  final int pieceIndex;
  @JsonKey(name: 'piece_total')
  final int pieceTotal;

  Map<String, Object?> toJson() => _$CarrierAssignmentUnitToJson(this);
}
