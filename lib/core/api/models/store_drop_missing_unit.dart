// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'missing_unit_reason.dart';

part 'store_drop_missing_unit.g.dart';

/// Producto que el chofer no pudo dejar en la entrega en tienda, con su motivo.
@JsonSerializable()
class StoreDropMissingUnit {
  const StoreDropMissingUnit({required this.unitId, required this.reason});

  factory StoreDropMissingUnit.fromJson(Map<String, Object?> json) =>
      _$StoreDropMissingUnitFromJson(json);

  /// Id de la unidad del pedido (uno de unit_ids de la entrega).
  @JsonKey(name: 'unit_id')
  final String unitId;
  final MissingUnitReason reason;

  Map<String, Object?> toJson() => _$StoreDropMissingUnitToJson(this);
}
