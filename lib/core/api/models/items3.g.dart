// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Items3 _$Items3FromJson(Map<String, dynamic> json) => Items3(
  sku: json['sku'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$Items3ToJson(Items3 instance) => <String, dynamic>{
  'sku': instance.sku,
  'name': instance.name,
  'quantity': instance.quantity,
  'image_url': instance.imageUrl,
};
