// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_stop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlannedStop _$PlannedStopFromJson(Map<String, dynamic> json) => PlannedStop(
  id: json['id'] as String,
  shipmentId: json['shipment_id'] as String,
  sequence: (json['sequence'] as num).toInt(),
  loadOrder: (json['load_order'] as num).toInt(),
  orderReference: json['order_reference'] as String?,
  customerName: json['customer_name'] as String?,
  shortAddress: json['short_address'] as String?,
  deliveryMode: json['delivery_mode'] == null
      ? null
      : DeliveryMode.fromJson(json['delivery_mode'] as String),
  unitsTotal: (json['units_total'] as num?)?.toInt(),
  timeWindow: json['time_window'] == null
      ? null
      : StopTimeWindow.fromJson(json['time_window'] as Map<String, dynamic>),
  address: json['address'] as String?,
  etaAt: json['eta_at'] == null
      ? null
      : DateTime.parse(json['eta_at'] as String),
  etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
  lane: json['lane'] as String?,
);

Map<String, dynamic> _$PlannedStopToJson(PlannedStop instance) =>
    <String, dynamic>{
      'order_reference': instance.orderReference,
      'customer_name': instance.customerName,
      'short_address': instance.shortAddress,
      'delivery_mode': instance.deliveryMode,
      'units_total': instance.unitsTotal,
      'time_window': instance.timeWindow,
      'address': instance.address,
      'id': instance.id,
      'shipment_id': instance.shipmentId,
      'sequence': instance.sequence,
      'eta_at': instance.etaAt?.toIso8601String(),
      'eta_minutes': instance.etaMinutes,
      'lane': instance.lane,
      'load_order': instance.loadOrder,
    };
