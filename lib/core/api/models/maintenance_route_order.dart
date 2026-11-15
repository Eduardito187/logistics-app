// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'maintenance_route_order.g.dart';

@JsonSerializable()
class MaintenanceRouteOrder {
  const MaintenanceRouteOrder({
    this.shipmentId,
    this.orderReference,
    this.customerName,
  });

  factory MaintenanceRouteOrder.fromJson(Map<String, Object?> json) =>
      _$MaintenanceRouteOrderFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;

  Map<String, Object?> toJson() => _$MaintenanceRouteOrderToJson(this);
}
