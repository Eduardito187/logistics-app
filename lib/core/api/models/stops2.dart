// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'method.dart';

part 'stops2.g.dart';

@JsonSerializable()
class Stops2 {
  const Stops2({
    this.shipmentId,
    this.sequence,
    this.orderReference,
    this.customerName,
    this.lat,
    this.lng,
    this.plannedEta,
    this.eta,
    this.remainingDistanceM,
    this.remainingDurationS,
    this.method,
    this.computedAt,
  });

  factory Stops2.fromJson(Map<String, Object?> json) => _$Stops2FromJson(json);

  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  final int? sequence;
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  final num? lat;
  final num? lng;
  @JsonKey(name: 'planned_eta')
  final DateTime? plannedEta;
  final DateTime? eta;
  @JsonKey(name: 'remaining_distance_m')
  final int? remainingDistanceM;
  @JsonKey(name: 'remaining_duration_s')
  final int? remainingDurationS;
  final Method? method;
  @JsonKey(name: 'computed_at')
  final DateTime? computedAt;

  Map<String, Object?> toJson() => _$Stops2ToJson(this);
}
