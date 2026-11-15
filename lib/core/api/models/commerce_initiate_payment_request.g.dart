// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_initiate_payment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceInitiatePaymentRequest _$CommerceInitiatePaymentRequestFromJson(
  Map<String, dynamic> json,
) => CommerceInitiatePaymentRequest(
  orderId: json['order_id'] as String,
  amountCents: (json['amount_cents'] as num).toInt(),
  method: json['method'] as String,
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$CommerceInitiatePaymentRequestToJson(
  CommerceInitiatePaymentRequest instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'amount_cents': instance.amountCents,
  'currency': instance.currency,
  'method': instance.method,
};
