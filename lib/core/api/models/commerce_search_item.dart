// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_search_item.g.dart';

@JsonSerializable()
class CommerceSearchItem {
  const CommerceSearchItem({
    required this.id,
    required this.name,
    required this.canonicalSku,
    required this.status,
    this.categoryId,
  });

  factory CommerceSearchItem.fromJson(Map<String, Object?> json) =>
      _$CommerceSearchItemFromJson(json);

  final String id;
  final String name;
  @JsonKey(name: 'canonical_sku')
  final String canonicalSku;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  final String status;

  Map<String, Object?> toJson() => _$CommerceSearchItemToJson(this);
}
