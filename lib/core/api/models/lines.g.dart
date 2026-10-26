// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lines.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lines _$LinesFromJson(Map<String, dynamic> json) => Lines(
  sku: json['sku'] as String,
  expectedQuantity: (json['expected_quantity'] as num).toInt(),
);

Map<String, dynamic> _$LinesToJson(Lines instance) => <String, dynamic>{
  'sku': instance.sku,
  'expected_quantity': instance.expectedQuantity,
};
