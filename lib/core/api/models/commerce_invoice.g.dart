// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceInvoice _$CommerceInvoiceFromJson(Map<String, dynamic> json) =>
    CommerceInvoice(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      customerName: json['customer_name'] as String,
      currency: json['currency'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => CommerceInvoiceLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      netCents: (json['net_cents'] as num).toInt(),
      ivaCents: (json['iva_cents'] as num).toInt(),
      totalCents: (json['total_cents'] as num).toInt(),
      status: CommerceInvoiceStatus.fromJson(json['status'] as String),
      number: json['number'] as String?,
      customerTaxId: json['customer_tax_id'] as String?,
      issuedAt: json['issued_at'] as String?,
    );

Map<String, dynamic> _$CommerceInvoiceToJson(CommerceInvoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'number': instance.number,
      'customer_name': instance.customerName,
      'customer_tax_id': instance.customerTaxId,
      'currency': instance.currency,
      'lines': instance.lines,
      'net_cents': instance.netCents,
      'iva_cents': instance.ivaCents,
      'total_cents': instance.totalCents,
      'status': instance.status,
      'issued_at': instance.issuedAt,
    };
