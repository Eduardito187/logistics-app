// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_set_product_physical_specs_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchSetProductPhysicalSpecsData _$BatchSetProductPhysicalSpecsDataFromJson(
  Map<String, dynamic> json,
) => BatchSetProductPhysicalSpecsData(
  results: (json['results'] as List<dynamic>?)
      ?.map((e) => Results.fromJson(e as Map<String, dynamic>))
      .toList(),
  summary: json['summary'] == null
      ? null
      : Summary.fromJson(json['summary'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BatchSetProductPhysicalSpecsDataToJson(
  BatchSetProductPhysicalSpecsData instance,
) => <String, dynamic>{
  'results': instance.results,
  'summary': instance.summary,
};
