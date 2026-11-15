// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Storage _$StorageFromJson(Map<String, dynamic> json) =>
    Storage(disk: json['disk'] as String?, path: json['path'] as String?);

Map<String, dynamic> _$StorageToJson(Storage instance) => <String, dynamic>{
  'disk': instance.disk,
  'path': instance.path,
};
