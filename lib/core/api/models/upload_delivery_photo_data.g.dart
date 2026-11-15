// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_delivery_photo_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadDeliveryPhotoData _$UploadDeliveryPhotoDataFromJson(
  Map<String, dynamic> json,
) => UploadDeliveryPhotoData(
  kind: UploadDeliveryPhotoDataKind.fromJson(json['kind'] as String),
  disk: json['disk'] as String,
  path: json['path'] as String,
  url: json['url'] as String?,
);

Map<String, dynamic> _$UploadDeliveryPhotoDataToJson(
  UploadDeliveryPhotoData instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'disk': instance.disk,
  'path': instance.path,
  'url': instance.url,
};
