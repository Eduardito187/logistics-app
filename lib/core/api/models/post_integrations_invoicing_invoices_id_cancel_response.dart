// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_ack.dart';

part 'post_integrations_invoicing_invoices_id_cancel_response.g.dart';

@JsonSerializable()
class PostIntegrationsInvoicingInvoicesIdCancelResponse {
  const PostIntegrationsInvoicingInvoicesIdCancelResponse({required this.data});

  factory PostIntegrationsInvoicingInvoicesIdCancelResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsInvoicingInvoicesIdCancelResponseFromJson(json);

  final CommerceAck data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsInvoicingInvoicesIdCancelResponseToJson(this);
}
