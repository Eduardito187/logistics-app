// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_invoice.dart';

part 'get_integrations_invoicing_invoices_id_response.g.dart';

@JsonSerializable()
class GetIntegrationsInvoicingInvoicesIdResponse {
  const GetIntegrationsInvoicingInvoicesIdResponse({required this.data});

  factory GetIntegrationsInvoicingInvoicesIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetIntegrationsInvoicingInvoicesIdResponseFromJson(json);

  final CommerceInvoice data;

  Map<String, Object?> toJson() =>
      _$GetIntegrationsInvoicingInvoicesIdResponseToJson(this);
}
