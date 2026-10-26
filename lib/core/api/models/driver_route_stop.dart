// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route_stop_status.dart';
import 'items3.dart';

part 'driver_route_stop.g.dart';

/// A stop of the driver route — what the driver drops at one point
@JsonSerializable()
class DriverRouteStop {
  const DriverRouteStop({
    required this.id,
    required this.shipmentId,
    required this.sequence,
    required this.items,
    required this.status,
    this.orderReference,
    this.customerName,
    this.customerPhone,
    this.address,
    this.addressReference,
    this.etaAt,
    this.lat,
    this.lng,
    this.settledAt,
  });

  factory DriverRouteStop.fromJson(Map<String, Object?> json) =>
      _$DriverRouteStopFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final int sequence;
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;

  /// Customer phone resolved from the shipment (cross-context). Null if unknown.
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;
  final String? address;

  /// Address reference/landmark (gate, floor) resolved from the shipment. Null if unknown.
  @JsonKey(name: 'address_reference')
  final String? addressReference;

  /// Order lines dropped at this stop, resolved from the shipment. Always present (empty when unknown).
  final List<Items3> items;
  @JsonKey(name: 'eta_at')
  final DateTime? etaAt;
  final double? lat;
  final double? lng;
  final DriverRouteStopStatus status;
  @JsonKey(name: 'settled_at')
  final DateTime? settledAt;

  Map<String, Object?> toJson() => _$DriverRouteStopToJson(this);
}
