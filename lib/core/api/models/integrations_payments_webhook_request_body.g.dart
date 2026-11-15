// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integrations_payments_webhook_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationsPaymentsWebhookRequestBody
_$IntegrationsPaymentsWebhookRequestBodyFromJson(Map<String, dynamic> json) =>
    IntegrationsPaymentsWebhookRequestBody(
      gatewayRef: json['gateway_ref'] as String,
      paymentId: json['payment_id'] as String?,
      orderId: json['order_id'] as String?,
    );

Map<String, dynamic> _$IntegrationsPaymentsWebhookRequestBodyToJson(
  IntegrationsPaymentsWebhookRequestBody instance,
) => <String, dynamic>{
  'payment_id': instance.paymentId,
  'order_id': instance.orderId,
  'gateway_ref': instance.gatewayRef,
};
