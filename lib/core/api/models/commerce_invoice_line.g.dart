// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_invoice_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceInvoiceLine _$CommerceInvoiceLineFromJson(Map<String, dynamic> json) =>
    CommerceInvoiceLine(
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPriceCents: (json['unit_price_cents'] as num).toInt(),
      lineTotalCents: (json['line_total_cents'] as num).toInt(),
    );

Map<String, dynamic> _$CommerceInvoiceLineToJson(
  CommerceInvoiceLine instance,
) => <String, dynamic>{
  'description': instance.description,
  'quantity': instance.quantity,
  'unit_price_cents': instance.unitPriceCents,
  'line_total_cents': instance.lineTotalCents,
};
