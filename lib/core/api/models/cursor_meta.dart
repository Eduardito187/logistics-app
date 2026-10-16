// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cursor_meta.g.dart';

/// Metadata added to a list response when cursor pagination is requested (E-02), preferred for large, growing collections. The caller follows `next_cursor` until it is null.
@JsonSerializable()
class CursorMeta {
  const CursorMeta({
    required this.count,
    required this.perPage,
    required this.hasMore,
    required this.nextCursor,
  });

  factory CursorMeta.fromJson(Map<String, Object?> json) =>
      _$CursorMetaFromJson(json);

  /// Number of items in this page.
  final int count;

  /// Page size used to slice the collection.
  @JsonKey(name: 'per_page')
  final int perPage;

  /// Whether more items remain after this page.
  @JsonKey(name: 'has_more')
  final bool hasMore;

  /// Opaque cursor for the next page, or null when exhausted.
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;

  Map<String, Object?> toJson() => _$CursorMetaToJson(this);
}
