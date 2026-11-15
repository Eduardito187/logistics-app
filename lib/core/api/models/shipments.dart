// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shipments.g.dart';

@JsonSerializable()
class Shipments {
  const Shipments({required this.shipmentId, required this.status});

  factory Shipments.fromJson(Map<String, Object?> json) =>
      _$ShipmentsFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final String status;

  Map<String, Object?> toJson() => _$ShipmentsToJson(this);
}
