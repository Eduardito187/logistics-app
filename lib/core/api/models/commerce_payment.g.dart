// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommercePayment _$CommercePaymentFromJson(Map<String, dynamic> json) =>
    CommercePayment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amount: CommerceMoney.fromJson(json['amount'] as Map<String, dynamic>),
      method: json['method'] as String,
      status: json['status'] as String,
      gatewayRef: json['gateway_ref'] as String?,
    );

Map<String, dynamic> _$CommercePaymentToJson(CommercePayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'amount': instance.amount,
      'method': instance.method,
      'status': instance.status,
      'gateway_ref': instance.gatewayRef,
    };
