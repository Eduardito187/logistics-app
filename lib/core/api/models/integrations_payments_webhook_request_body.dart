// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'integrations_payments_webhook_request_body.g.dart';

@JsonSerializable()
class IntegrationsPaymentsWebhookRequestBody {
  const IntegrationsPaymentsWebhookRequestBody({
    required this.gatewayRef,
    this.paymentId,
    this.orderId,
  });

  factory IntegrationsPaymentsWebhookRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$IntegrationsPaymentsWebhookRequestBodyFromJson(json);

  /// Id del pago (alternativo a order_id).
  @JsonKey(name: 'payment_id')
  final String? paymentId;

  /// Id de la orden (alternativo a payment_id).
  @JsonKey(name: 'order_id')
  final String? orderId;

  /// Referencia del cobro en el proveedor.
  @JsonKey(name: 'gateway_ref')
  final String gatewayRef;

  Map<String, Object?> toJson() =>
      _$IntegrationsPaymentsWebhookRequestBodyToJson(this);
}
