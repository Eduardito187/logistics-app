// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_sap_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportedSapOrder _$ImportedSapOrderFromJson(Map<String, dynamic> json) =>
    ImportedSapOrder(
      externalId: json['external_id'] as String,
      customerName: json['customer_name'] as String,
      addressText: json['address_text'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => ImportedSapOrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      addressReference: json['address_reference'] as String?,
    );

Map<String, dynamic> _$ImportedSapOrderToJson(ImportedSapOrder instance) =>
    <String, dynamic>{
      'external_id': instance.externalId,
      'customer_name': instance.customerName,
      'address_text': instance.addressText,
      'address_reference': instance.addressReference,
      'lines': instance.lines,
    };
