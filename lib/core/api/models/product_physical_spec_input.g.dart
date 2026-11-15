// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_physical_spec_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductPhysicalSpecInput _$ProductPhysicalSpecInputFromJson(
  Map<String, dynamic> json,
) => ProductPhysicalSpecInput(
  weightKg: json['weight_kg'] as num?,
  lengthCm: json['length_cm'] as num?,
  widthCm: json['width_cm'] as num?,
  heightCm: json['height_cm'] as num?,
);

Map<String, dynamic> _$ProductPhysicalSpecInputToJson(
  ProductPhysicalSpecInput instance,
) => <String, dynamic>{
  'weight_kg': instance.weightKg,
  'length_cm': instance.lengthCm,
  'width_cm': instance.widthCm,
  'height_cm': instance.heightCm,
};
