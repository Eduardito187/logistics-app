// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'failed.g.dart';

@JsonSerializable()
class Failed {
  const Failed({this.shipmentId, this.externalId, this.reason});

  factory Failed.fromJson(Map<String, Object?> json) => _$FailedFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  @JsonKey(name: 'external_id')
  final String? externalId;
  final String? reason;

  Map<String, Object?> toJson() => _$FailedToJson(this);
}
