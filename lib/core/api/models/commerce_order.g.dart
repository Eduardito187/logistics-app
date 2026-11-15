// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceOrder _$CommerceOrderFromJson(Map<String, dynamic> json) =>
    CommerceOrder(
      id: json['id'] as String,
      status: json['status'] as String,
      currency: json['currency'] as String,
      totalCents: (json['total_cents'] as num).toInt(),
      shipmentRequested: json['shipment_requested'] as bool,
      shipTo: CommerceShipTo.fromJson(json['ship_to'] as Map<String, dynamic>),
      lines: (json['lines'] as List<dynamic>)
          .map((e) => CommerceOrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      customerId: json['customer_id'] as String?,
    );

Map<String, dynamic> _$CommerceOrderToJson(CommerceOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'status': instance.status,
      'currency': instance.currency,
      'total_cents': instance.totalCents,
      'shipment_requested': instance.shipmentRequested,
      'ship_to': instance.shipTo,
      'lines': instance.lines,
    };
