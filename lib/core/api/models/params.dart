// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'params.g.dart';

@JsonSerializable()
class Params {
  const Params({
    this.departAt,
    this.capacitySlack,
    this.defaultWeightKgPerPackage,
    this.defaultVolumeM3PerPackage,
    this.originNodeId,
  });

  factory Params.fromJson(Map<String, Object?> json) => _$ParamsFromJson(json);

  /// Depot departure time (ISO-8601); ETAs are computed from here.
  @JsonKey(name: 'depart_at')
  final DateTime? departAt;

  /// Fraction of nominal kg/m3 reserved as slack (0..1).
  @JsonKey(name: 'capacity_slack')
  final num? capacitySlack;
  @JsonKey(name: 'default_weight_kg_per_package')
  final num? defaultWeightKgPerPackage;
  @JsonKey(name: 'default_volume_m3_per_package')
  final num? defaultVolumeM3PerPackage;
  @JsonKey(name: 'origin_node_id')
  final String? originNodeId;

  Map<String, Object?> toJson() => _$ParamsToJson(this);
}
