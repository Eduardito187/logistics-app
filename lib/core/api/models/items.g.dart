// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Items _$ItemsFromJson(Map<String, dynamic> json) => Items(
  sku: json['sku'] as String,
  weightKg: json['weight_kg'] as num?,
  lengthCm: json['length_cm'] as num?,
  widthCm: json['width_cm'] as num?,
  heightCm: json['height_cm'] as num?,
);

Map<String, dynamic> _$ItemsToJson(Items instance) => <String, dynamic>{
  'weight_kg': instance.weightKg,
  'length_cm': instance.lengthCm,
  'width_cm': instance.widthCm,
  'height_cm': instance.heightCm,
  'sku': instance.sku,
};
