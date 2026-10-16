// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pagination_meta.g.dart';

/// Metadata added to a list response when offset pagination is requested (E-02). Absent when the caller does not pass any pagination parameter (the full collection is returned unchanged).
@JsonSerializable()
class PaginationMeta {
  const PaginationMeta({
    required this.count,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    this.nextPage,
    this.prevPage,
  });

  factory PaginationMeta.fromJson(Map<String, Object?> json) =>
      _$PaginationMetaFromJson(json);

  /// Number of items in this page.
  final int count;

  /// 1-based page number of this page.
  final int page;

  /// Page size used to slice the collection.
  @JsonKey(name: 'per_page')
  final int perPage;

  /// Total number of items across all pages.
  final int total;

  /// Total number of pages for the current page size.
  @JsonKey(name: 'total_pages')
  final int totalPages;

  /// Next page number, or null on the last page.
  @JsonKey(name: 'next_page')
  final int? nextPage;

  /// Previous page number, or null on the first page.
  @JsonKey(name: 'prev_page')
  final int? prevPage;

  Map<String, Object?> toJson() => _$PaginationMetaToJson(this);
}
