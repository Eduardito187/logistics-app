// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_sap_order_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportedSapOrderLine _$ImportedSapOrderLineFromJson(
  Map<String, dynamic> json,
) => ImportedSapOrderLine(
  sku: json['sku'] as String,
  productName: json['product_name'] as String,
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$ImportedSapOrderLineToJson(
  ImportedSapOrderLine instance,
) => <String, dynamic>{
  'sku': instance.sku,
  'product_name': instance.productName,
  'quantity': instance.quantity,
};
