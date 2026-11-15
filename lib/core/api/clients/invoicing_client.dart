// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_integrations_invoicing_invoices_by_order_order_id_response.dart';
import '../models/get_integrations_invoicing_invoices_id_response.dart';
import '../models/post_integrations_invoicing_invoices_id_cancel_response.dart';

part 'invoicing_client.g.dart';

@RestApi()
abstract class InvoicingClient {
  factory InvoicingClient(Dio dio, {String? baseUrl}) = _InvoicingClient;

  /// Get an invoice by id
  @GET('/integrations/invoicing/invoices/{id}')
  Future<GetIntegrationsInvoicingInvoicesIdResponse> getInvoice({
    @Path('id') required String id,
  });

  /// Get the invoice of an order
  @GET('/integrations/invoicing/invoices/by-order/{orderId}')
  Future<GetIntegrationsInvoicingInvoicesByOrderOrderIdResponse>
  getInvoiceByOrder({@Path('orderId') required String orderId});

  /// Cancel an invoice
  @POST('/integrations/invoicing/invoices/{id}/cancel')
  Future<PostIntegrationsInvoicingInvoicesIdCancelResponse> cancelInvoice({
    @Path('id') required String id,
  });

  /// Render the printable invoice document (internal)
  @GET('/integrations/invoicing/invoices/{id}/document')
  Future<String> renderInvoiceDocument({@Path('id') required String id});
}
