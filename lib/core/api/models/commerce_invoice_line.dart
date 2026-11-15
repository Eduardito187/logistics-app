// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_invoice_line.g.dart';

@JsonSerializable()
class CommerceInvoiceLine {
  const CommerceInvoiceLine({
    required this.description,
    required this.quantity,
    required this.unitPriceCents,
    required this.lineTotalCents,
  });

  factory CommerceInvoiceLine.fromJson(Map<String, Object?> json) =>
      _$CommerceInvoiceLineFromJson(json);

  final String description;
  final int quantity;
  @JsonKey(name: 'unit_price_cents')
  final int unitPriceCents;
  @JsonKey(name: 'line_total_cents')
  final int lineTotalCents;

  Map<String, Object?> toJson() => _$CommerceInvoiceLineToJson(this);
}
