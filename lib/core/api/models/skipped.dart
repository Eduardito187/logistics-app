// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'skipped.g.dart';

@JsonSerializable()
class Skipped {
  const Skipped({this.shipmentId, this.externalId, this.reason});

  factory Skipped.fromJson(Map<String, Object?> json) =>
      _$SkippedFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  @JsonKey(name: 'external_id')
  final String? externalId;

  /// closed:delivered | closed:failed | closed:cancelled
  final String? reason;

  Map<String, Object?> toJson() => _$SkippedToJson(this);
}
