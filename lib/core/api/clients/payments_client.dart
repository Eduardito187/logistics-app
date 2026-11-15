// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/commerce_initiate_payment_request.dart';
import '../models/integrations_payments_webhook_request_body.dart';
import '../models/post_channels_payments_response.dart';

part 'payments_client.g.dart';

@RestApi()
abstract class PaymentsClient {
  factory PaymentsClient(Dio dio, {String? baseUrl}) = _PaymentsClient;

  /// Payment gateway capture webhook (idempotent).
  ///
  /// La pasarela confirma el cobro de un pago (frente comercial, ADR 018 / EC-F0-07). Despacha la.
  /// captura por el CommandBus; es idempotente por el pago/orden, así que un reintento del proveedor.
  /// no duplica la captura. Identifica el pago por payment_id o por order_id.
  @POST('/integrations/payments/webhook')
  Future<AcceptedEnvelope> paymentsWebhook({
    @Body() required IntegrationsPaymentsWebhookRequestBody body,
  });

  /// Initiate the payment of an order.
  ///
  /// Starts the charge of an order and returns the payment with its gateway reference, which the storefront uses to redirect the customer to the gateway checkout. The final state is confirmed later by the gateway webhook (integrations gate).
  @POST('/channels/payments')
  Future<PostChannelsPaymentsResponse> initiatePayment({
    @Body() required CommerceInitiatePaymentRequest body,
  });
}
