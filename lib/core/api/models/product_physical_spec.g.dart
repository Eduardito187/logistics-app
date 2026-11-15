// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_physical_spec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductPhysicalSpec _$ProductPhysicalSpecFromJson(Map<String, dynamic> json) =>
    ProductPhysicalSpec(
      weightKg: json['weight_kg'] as num?,
      lengthCm: json['length_cm'] as num?,
      widthCm: json['width_cm'] as num?,
      heightCm: json['height_cm'] as num?,
      volumeM3: json['volume_m3'] as num?,
    );

Map<String, dynamic> _$ProductPhysicalSpecToJson(
  ProductPhysicalSpec instance,
) => <String, dynamic>{
  'weight_kg': instance.weightKg,
  'length_cm': instance.lengthCm,
  'width_cm': instance.widthCm,
  'height_cm': instance.heightCm,
  'volume_m3': instance.volumeM3,
};
