// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Load2 _$Load2FromJson(Map<String, dynamic> json) => Load2(
  description: json['description'] as String?,
  weightKg: (json['weight_kg'] as num?)?.toDouble(),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => Items2.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Load2ToJson(Load2 instance) => <String, dynamic>{
  'description': instance.description,
  'weight_kg': instance.weightKg,
  'items': instance.items,
};
