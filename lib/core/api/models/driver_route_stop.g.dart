// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_route_stop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverRouteStop _$DriverRouteStopFromJson(Map<String, dynamic> json) =>
    DriverRouteStop(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      sequence: (json['sequence'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => Items3.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: DriverRouteStopStatus.fromJson(json['status'] as String),
      orderReference: json['order_reference'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      address: json['address'] as String?,
      addressReference: json['address_reference'] as String?,
      etaAt: json['eta_at'] == null
          ? null
          : DateTime.parse(json['eta_at'] as String),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      settledAt: json['settled_at'] == null
          ? null
          : DateTime.parse(json['settled_at'] as String),
      arrivedAt: json['arrived_at'] == null
          ? null
          : DateTime.parse(json['arrived_at'] as String),
      arrivalSource: json['arrival_source'] == null
          ? null
          : DriverRouteStopArrivalSource.fromJson(
              json['arrival_source'] as String,
            ),
      deliveryMode: json['delivery_mode'] == null
          ? null
          : DeliveryMode.fromJson(json['delivery_mode'] as String),
      destinationNodeId: json['destination_node_id'] as String?,
      destinationNodeName: json['destination_node_name'] as String?,
      unitsTotal: (json['units_total'] as num?)?.toInt(),
      unitIds: (json['unit_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      destination: json['destination'] == null
          ? null
          : Destination.fromJson(json['destination'] as Map<String, dynamic>),
      podConfirmation: json['pod_confirmation'] as String?,
      podPhotoUrl: json['pod_photo_url'] as String?,
    );

Map<String, dynamic> _$DriverRouteStopToJson(DriverRouteStop instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shipment_id': instance.shipmentId,
      'sequence': instance.sequence,
      'order_reference': instance.orderReference,
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'address': instance.address,
      'address_reference': instance.addressReference,
      'items': instance.items,
      'eta_at': instance.etaAt?.toIso8601String(),
      'lat': instance.lat,
      'lng': instance.lng,
      'status': instance.status,
      'settled_at': instance.settledAt?.toIso8601String(),
      'arrived_at': instance.arrivedAt?.toIso8601String(),
      'arrival_source': instance.arrivalSource,
      'delivery_mode': instance.deliveryMode,
      'destination_node_id': instance.destinationNodeId,
      'destination_node_name': instance.destinationNodeName,
      'units_total': instance.unitsTotal,
      'unit_ids': instance.unitIds,
      'destination': instance.destination,
      'pod_confirmation': instance.podConfirmation,
      'pod_photo_url': instance.podPhotoUrl,
    };
