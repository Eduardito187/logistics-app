// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_mode.dart';
import 'stop_time_window.dart';

part 'stop_eta.g.dart';

@JsonSerializable()
class StopEta {
  const StopEta({
    required this.shipmentId,
    required this.sequence,
    this.orderReference,
    this.customerName,
    this.shortAddress,
    this.deliveryMode,
    this.unitsTotal,
    this.timeWindow,
    this.etaAt,
    this.etaMinutes,
  });

  factory StopEta.fromJson(Map<String, Object?> json) =>
      _$StopEtaFromJson(json);

  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;

  /// Same rule as Shipment.short_address.
  @JsonKey(name: 'short_address')
  final String? shortAddress;
  @JsonKey(name: 'delivery_mode')
  final DeliveryMode? deliveryMode;
  @JsonKey(name: 'units_total')
  final int? unitsTotal;
  @JsonKey(name: 'time_window')
  final StopTimeWindow? timeWindow;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final int sequence;
  @JsonKey(name: 'eta_at')
  final DateTime? etaAt;
  @JsonKey(name: 'eta_minutes')
  final int? etaMinutes;

  Map<String, Object?> toJson() => _$StopEtaToJson(this);
}
