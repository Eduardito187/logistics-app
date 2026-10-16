// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receive_shipment_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiveShipmentLine _$ReceiveShipmentLineFromJson(Map<String, dynamic> json) =>
    ReceiveShipmentLine(
      sku: json['sku'] as String,
      productName: json['product_name'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$ReceiveShipmentLineToJson(
  ReceiveShipmentLine instance,
) => <String, dynamic>{
  'sku': instance.sku,
  'product_name': instance.productName,
  'quantity': instance.quantity,
};
