// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'collection_meta.g.dart';

@JsonSerializable()
class CollectionMeta {
  const CollectionMeta({this.count});

  factory CollectionMeta.fromJson(Map<String, Object?> json) =>
      _$CollectionMetaFromJson(json);

  final int? count;

  Map<String, Object?> toJson() => _$CollectionMetaToJson(this);
}
