// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/commerce_cancel_order_request.dart';
import '../models/commerce_checkout_request.dart';
import '../models/commerce_credit_signal_request.dart';
import '../models/commerce_place_order_request.dart';
import '../models/get_channels_orders_order_response.dart';
import '../models/post_channels_checkout_response.dart';
import '../models/post_channels_orders_order_cancel_response.dart';
import '../models/post_channels_orders_response.dart';
import '../models/post_integrations_orders_order_cancel_response.dart';
import '../models/post_integrations_orders_order_contract_signed_response.dart';
import '../models/post_integrations_orders_order_initial_paid_response.dart';

part 'orders_client.g.dart';

@RestApi()
abstract class OrdersClient {
  factory OrdersClient(Dio dio, {String? baseUrl}) = _OrdersClient;

  /// Place an order (checkout).
  ///
  /// Creates a commercial order from the checkout snapshot (lines with frozen unit price in cents and the delivery address). Asynchronous: the command is persisted transactionally and its events go through the outbox (payment and fulfillment happen afterwards), so the response is a 202 acknowledgement without the generated order id.
  @POST('/channels/orders')
  Future<PostChannelsOrdersResponse> placeOrder({
    @Body() required CommercePlaceOrderRequest body,
  });

  /// Get an order by id.
  ///
  /// [order] - Order id.
  @GET('/channels/orders/{order}')
  Future<GetChannelsOrdersOrderResponse> getOrder({
    @Path('order') required String order,
  });

  /// Place an order from an existing cart (checkout).
  ///
  /// Creates the order from a cart snapshot (lines and frozen price come from the cart, not the body) plus the delivery address. Asynchronous (202); the cart is marked converted via the outbox.
  @POST('/channels/checkout')
  Future<PostChannelsCheckoutResponse> checkout({
    @Body() required CommerceCheckoutRequest body,
  });

  /// Cancel an order (POS / customer channel)
  @POST('/channels/orders/{order}/cancel')
  Future<PostChannelsOrdersOrderCancelResponse> cancelOrderChannel({
    @Path('order') required String order,
    @Body() CommerceCancelOrderRequest? body,
  });

  /// Cancel an order (POS backend / service)
  @POST('/integrations/orders/{order}/cancel')
  Future<PostIntegrationsOrdersOrderCancelResponse> cancelOrderIntegration({
    @Path('order') required String order,
    @Body() CommerceCancelOrderRequest? body,
  });

  /// Report the credit contract signature (credit/installment orders).
  ///
  /// Señal del POS/sistema de crédito: el contrato de la orden a crédito fue firmado. Al cumplirse las condiciones del plan (crédito sin inicial → solo contrato; con inicial → contrato + inicial) la orden pasa a procesando (emite OrderPaid → crea el envío → tracking «procesando»). Idempotente.
  @POST('/integrations/orders/{order}/contract-signed')
  Future<PostIntegrationsOrdersOrderContractSignedResponse> signOrderContract({
    @Path('order') required String order,
    @Body() CommerceCreditSignalRequest? body,
  });

  /// Report the down-payment of a credit order (credit with down payment).
  ///
  /// Señal del POS/sistema de crédito: se cobró la cuota inicial de una orden de crédito con inicial. Junto a la firma del contrato habilita el paso a procesando. Idempotente. 422 si la orden no es a crédito o no lleva inicial.
  @POST('/integrations/orders/{order}/initial-paid')
  Future<PostIntegrationsOrdersOrderInitialPaidResponse>
  recordOrderInitialPayment({
    @Path('order') required String order,
    @Body() CommerceCreditSignalRequest? body,
  });
}
