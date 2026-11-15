// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'surplus2.g.dart';

@JsonSerializable()
class Surplus2 {
  const Surplus2({this.unitId, this.belongsToShipmentId});

  factory Surplus2.fromJson(Map<String, Object?> json) =>
      _$Surplus2FromJson(json);

  @JsonKey(name: 'unit_id')
  final String? unitId;
  @JsonKey(name: 'belongs_to_shipment_id')
  final String? belongsToShipmentId;

  Map<String, Object?> toJson() => _$Surplus2ToJson(this);
}
