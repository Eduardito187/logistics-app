// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Load _$LoadFromJson(Map<String, dynamic> json) => Load(
  description: json['description'] as String?,
  weightKg: (json['weight_kg'] as num?)?.toDouble(),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => Items.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LoadToJson(Load instance) => <String, dynamic>{
  'description': instance.description,
  'weight_kg': instance.weightKg,
  'items': instance.items,
};
