// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_product_physical_spec_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetProductPhysicalSpecData _$SetProductPhysicalSpecDataFromJson(
  Map<String, dynamic> json,
) => SetProductPhysicalSpecData(
  canonicalSku: json['canonical_sku'] as String?,
  name: json['name'] as String?,
  physicalSpec: json['physical_spec'] == null
      ? null
      : ProductPhysicalSpec.fromJson(
          json['physical_spec'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SetProductPhysicalSpecDataToJson(
  SetProductPhysicalSpecData instance,
) => <String, dynamic>{
  'canonical_sku': instance.canonicalSku,
  'name': instance.name,
  'physical_spec': instance.physicalSpec,
};
