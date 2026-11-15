// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_search_facet.g.dart';

@JsonSerializable()
class CommerceSearchFacet {
  const CommerceSearchFacet({required this.count, this.categoryId});

  factory CommerceSearchFacet.fromJson(Map<String, Object?> json) =>
      _$CommerceSearchFacetFromJson(json);

  @JsonKey(name: 'category_id')
  final String? categoryId;
  final int count;

  Map<String, Object?> toJson() => _$CommerceSearchFacetToJson(this);
}
