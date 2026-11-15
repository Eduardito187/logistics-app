// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_invoice.dart';

part 'get_integrations_invoicing_invoices_by_order_order_id_response.g.dart';

@JsonSerializable()
class GetIntegrationsInvoicingInvoicesByOrderOrderIdResponse {
  const GetIntegrationsInvoicingInvoicesByOrderOrderIdResponse({
    required this.data,
  });

  factory GetIntegrationsInvoicingInvoicesByOrderOrderIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetIntegrationsInvoicingInvoicesByOrderOrderIdResponseFromJson(json);

  final CommerceInvoice data;

  Map<String, Object?> toJson() =>
      _$GetIntegrationsInvoicingInvoicesByOrderOrderIdResponseToJson(this);
}
