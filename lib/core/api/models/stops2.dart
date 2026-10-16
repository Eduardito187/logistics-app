// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'stops2.g.dart';

@JsonSerializable()
class Stops2 {
  const Stops2({
    required this.shipmentId,
    required this.latitude,
    required this.longitude,
  });

  factory Stops2.fromJson(Map<String, Object?> json) => _$Stops2FromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final double latitude;
  final double longitude;

  Map<String, Object?> toJson() => _$Stops2ToJson(this);
}
