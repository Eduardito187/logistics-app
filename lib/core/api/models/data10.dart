// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data10.g.dart';

@JsonSerializable()
class Data10 {
  const Data10({required this.shipmentId, required this.accepted});

  factory Data10.fromJson(Map<String, Object?> json) => _$Data10FromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final bool accepted;

  Map<String, Object?> toJson() => _$Data10ToJson(this);
}
