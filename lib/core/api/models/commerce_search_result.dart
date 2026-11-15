// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_search_item.dart';

part 'commerce_search_result.g.dart';

@JsonSerializable()
class CommerceSearchResult {
  const CommerceSearchResult({
    required this.items,
    required this.nextCursor,
    this.total,
  });

  factory CommerceSearchResult.fromJson(Map<String, Object?> json) =>
      _$CommerceSearchResultFromJson(json);

  final List<CommerceSearchItem> items;
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;

  /// Total hit count, present only on the first page.
  final int? total;

  Map<String, Object?> toJson() => _$CommerceSearchResultToJson(this);
}
