// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_route_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceRouteOrder _$MaintenanceRouteOrderFromJson(
  Map<String, dynamic> json,
) => MaintenanceRouteOrder(
  shipmentId: json['shipment_id'] as String?,
  orderReference: json['order_reference'] as String?,
  customerName: json['customer_name'] as String?,
);

Map<String, dynamic> _$MaintenanceRouteOrderToJson(
  MaintenanceRouteOrder instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'order_reference': instance.orderReference,
  'customer_name': instance.customerName,
};
