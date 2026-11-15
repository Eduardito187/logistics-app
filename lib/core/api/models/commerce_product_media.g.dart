// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_product_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceProductMedia _$CommerceProductMediaFromJson(
  Map<String, dynamic> json,
) => CommerceProductMedia(
  path: json['path'] as String,
  alt: json['alt'] as String,
  position: (json['position'] as num).toInt(),
);

Map<String, dynamic> _$CommerceProductMediaToJson(
  CommerceProductMedia instance,
) => <String, dynamic>{
  'path': instance.path,
  'alt': instance.alt,
  'position': instance.position,
};
