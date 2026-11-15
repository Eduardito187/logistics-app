// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_invoice_line.dart';
import 'commerce_invoice_status.dart';

part 'commerce_invoice.g.dart';

@JsonSerializable()
class CommerceInvoice {
  const CommerceInvoice({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.currency,
    required this.lines,
    required this.netCents,
    required this.ivaCents,
    required this.totalCents,
    required this.status,
    this.number,
    this.customerTaxId,
    this.issuedAt,
  });

  factory CommerceInvoice.fromJson(Map<String, Object?> json) =>
      _$CommerceInvoiceFromJson(json);

  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  final String? number;
  @JsonKey(name: 'customer_name')
  final String customerName;
  @JsonKey(name: 'customer_tax_id')
  final String? customerTaxId;
  final String currency;
  final List<CommerceInvoiceLine> lines;
  @JsonKey(name: 'net_cents')
  final int netCents;
  @JsonKey(name: 'iva_cents')
  final int ivaCents;
  @JsonKey(name: 'total_cents')
  final int totalCents;
  final CommerceInvoiceStatus status;
  @JsonKey(name: 'issued_at')
  final String? issuedAt;

  Map<String, Object?> toJson() => _$CommerceInvoiceToJson(this);
}
