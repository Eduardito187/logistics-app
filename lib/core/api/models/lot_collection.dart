// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'list_meta.dart';
import 'lot.dart';

part 'lot_collection.g.dart';

@JsonSerializable()
class LotCollection {
  const LotCollection({required this.data, this.meta});

  factory LotCollection.fromJson(Map<String, Object?> json) =>
      _$LotCollectionFromJson(json);

  final List<Lot> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() => _$LotCollectionToJson(this);
}
