// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_checkout_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceCheckoutRequest _$CommerceCheckoutRequestFromJson(
  Map<String, dynamic> json,
) => CommerceCheckoutRequest(
  cartId: json['cart_id'] as String,
  shipTo: CommerceShipTo.fromJson(json['ship_to'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CommerceCheckoutRequestToJson(
  CommerceCheckoutRequest instance,
) => <String, dynamic>{'cart_id': instance.cartId, 'ship_to': instance.shipTo};
