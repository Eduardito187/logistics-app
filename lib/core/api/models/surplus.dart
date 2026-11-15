// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'surplus.g.dart';

@JsonSerializable()
class Surplus {
  const Surplus({required this.unitId, this.belongsToShipmentId});

  factory Surplus.fromJson(Map<String, Object?> json) =>
      _$SurplusFromJson(json);

  @JsonKey(name: 'unit_id')
  final String unitId;
  @JsonKey(name: 'belongs_to_shipment_id')
  final String? belongsToShipmentId;

  Map<String, Object?> toJson() => _$SurplusToJson(this);
}
