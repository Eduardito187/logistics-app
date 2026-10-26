// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asn_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AsnLine _$AsnLineFromJson(Map<String, dynamic> json) => AsnLine(
  sku: json['sku'] as String,
  expectedQuantity: (json['expected_quantity'] as num).toInt(),
);

Map<String, dynamic> _$AsnLineToJson(AsnLine instance) => <String, dynamic>{
  'sku': instance.sku,
  'expected_quantity': instance.expectedQuantity,
};
