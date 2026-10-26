// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReturnLine _$ReturnLineFromJson(Map<String, dynamic> json) => ReturnLine(
  sku: json['sku'] as String,
  quantity: (json['quantity'] as num).toInt(),
  reason: json['reason'] as String,
);

Map<String, dynamic> _$ReturnLineToJson(ReturnLine instance) =>
    <String, dynamic>{
      'sku': instance.sku,
      'quantity': instance.quantity,
      'reason': instance.reason,
    };
