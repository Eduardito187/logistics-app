// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'points.dart';
import 'window.dart';

part 'shipment_breadcrumbs.g.dart';

@JsonSerializable()
class ShipmentBreadcrumbs {
  const ShipmentBreadcrumbs({
    this.shipmentId,
    this.vehicleId,
    this.plate,
    this.deliveryStatus,
    this.window,
    this.pointsTotal,
    this.pointsReturned,
    this.points,
  });

  factory ShipmentBreadcrumbs.fromJson(Map<String, Object?> json) =>
      _$ShipmentBreadcrumbsFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  final String? plate;
  @JsonKey(name: 'delivery_status')
  final String? deliveryStatus;
  final Window? window;
  @JsonKey(name: 'points_total')
  final int? pointsTotal;
  @JsonKey(name: 'points_returned')
  final int? pointsReturned;
  final List<Points>? points;

  Map<String, Object?> toJson() => _$ShipmentBreadcrumbsToJson(this);
}
