// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_breadcrumbs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentBreadcrumbs _$ShipmentBreadcrumbsFromJson(Map<String, dynamic> json) =>
    ShipmentBreadcrumbs(
      shipmentId: json['shipment_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      plate: json['plate'] as String?,
      deliveryStatus: json['delivery_status'] as String?,
      window: json['window'] == null
          ? null
          : Window.fromJson(json['window'] as Map<String, dynamic>),
      pointsTotal: (json['points_total'] as num?)?.toInt(),
      pointsReturned: (json['points_returned'] as num?)?.toInt(),
      points: (json['points'] as List<dynamic>?)
          ?.map((e) => Points.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ShipmentBreadcrumbsToJson(
  ShipmentBreadcrumbs instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'vehicle_id': instance.vehicleId,
  'plate': instance.plate,
  'delivery_status': instance.deliveryStatus,
  'window': instance.window,
  'points_total': instance.pointsTotal,
  'points_returned': instance.pointsReturned,
  'points': instance.points,
};
