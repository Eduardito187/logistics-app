// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'storage.g.dart';

@JsonSerializable()
class Storage {
  const Storage({this.disk, this.path});

  factory Storage.fromJson(Map<String, Object?> json) =>
      _$StorageFromJson(json);

  final String? disk;
  final String? path;

  Map<String, Object?> toJson() => _$StorageToJson(this);
}
