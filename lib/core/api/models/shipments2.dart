// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shipments2.g.dart';

@JsonSerializable()
class Shipments2 {
  const Shipments2({
    this.shipmentId,
    this.externalId,
    this.customerName,
    this.status,
    this.currentDate,
    this.currentWindowStart,
    this.currentWindowEnd,
  });

  factory Shipments2.fromJson(Map<String, Object?> json) =>
      _$Shipments2FromJson(json);

  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  @JsonKey(name: 'external_id')
  final String? externalId;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  final String? status;
  @JsonKey(name: 'current_date')
  final DateTime? currentDate;
  @JsonKey(name: 'current_window_start')
  final String? currentWindowStart;
  @JsonKey(name: 'current_window_end')
  final String? currentWindowEnd;

  Map<String, Object?> toJson() => _$Shipments2ToJson(this);
}
