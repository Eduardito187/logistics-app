// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffPhoto _$StaffPhotoFromJson(Map<String, dynamic> json) => StaffPhoto(
  kind: json['kind'] == null
      ? null
      : StaffPhotoKind.fromJson(json['kind'] as String),
  url: json['url'] as String?,
  at: json['at'] == null ? null : DateTime.parse(json['at'] as String),
  label: json['label'] as String?,
  side: json['side'] == null
      ? null
      : StaffDocumentSide.fromJson(json['side'] as String),
);

Map<String, dynamic> _$StaffPhotoToJson(StaffPhoto instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'url': instance.url,
      'at': instance.at?.toIso8601String(),
      'label': instance.label,
      'side': instance.side,
    };
