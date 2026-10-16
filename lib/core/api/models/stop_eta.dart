// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'stop_eta.g.dart';

@JsonSerializable()
class StopEta {
  const StopEta({
    required this.shipmentId,
    required this.sequence,
    this.etaAt,
    this.etaMinutes,
  });

  factory StopEta.fromJson(Map<String, Object?> json) =>
      _$StopEtaFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final int sequence;
  @JsonKey(name: 'eta_at')
  final DateTime? etaAt;
  @JsonKey(name: 'eta_minutes')
  final int? etaMinutes;

  Map<String, Object?> toJson() => _$StopEtaToJson(this);
}
