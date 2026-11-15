// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_place_order_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommercePlaceOrderRequest _$CommercePlaceOrderRequestFromJson(
  Map<String, dynamic> json,
) => CommercePlaceOrderRequest(
  shipTo: CommerceShipTo.fromJson(json['ship_to'] as Map<String, dynamic>),
  lines: (json['lines'] as List<dynamic>)
      .map((e) => CommerceOrderLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  financing: json['financing'] == null
      ? CommercePlaceOrderRequestFinancing.cash
      : CommercePlaceOrderRequestFinancing.fromJson(
          json['financing'] as String,
        ),
  customerId: json['customer_id'] as String?,
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$CommercePlaceOrderRequestToJson(
  CommercePlaceOrderRequest instance,
) => <String, dynamic>{
  'customer_id': instance.customerId,
  'currency': instance.currency,
  'financing': instance.financing,
  'ship_to': instance.shipTo,
  'lines': instance.lines,
};
