// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment_status_counts.dart';

part 'list_meta.g.dart';

/// Single, named meta of every list response (snake_case). `count` is always present. Offset pagination adds page/per_page/total/total_pages/next_page/prev_page; cursor pagination adds per_page/has_more/ next_cursor. Absent pagination fields mean the caller did not paginate (full collection). Endpoints may add their own keys (e.g. unread_count, count_by_status, date).
@JsonSerializable()
class ListMeta {
  const ListMeta({
    required this.count,
    this.page,
    this.perPage,
    this.total,
    this.totalPages,
    this.unread,
    this.unreadCount,
    this.date,
    this.dateTo,
    this.countByStatus,
    this.unacknowledgedTotal,
    this.nextPage,
    this.prevPage,
    this.hasMore,
    this.nextCursor,
  });

  factory ListMeta.fromJson(Map<String, Object?> json) =>
      _$ListMetaFromJson(json);

  /// Number of items in this response.
  final int count;

  /// 1-based page number (offset pagination).
  final int? page;

  /// Page size used.
  @JsonKey(name: 'per_page')
  final int? perPage;

  /// Total items across all pages (offset pagination).
  final int? total;
  @JsonKey(name: 'total_pages')
  final int? totalPages;

  /// Solo en GET /app/inbox: total de pendientes del usuario (para el badge).
  final int? unread;

  /// Notifications not yet read by the authenticated user (bell badge).
  @JsonKey(name: 'unread_count')
  final int? unreadCount;
  final DateTime? date;
  @JsonKey(name: 'date_to')
  final DateTime? dateTo;
  @JsonKey(name: 'count_by_status')
  final ShipmentStatusCounts? countByStatus;
  @JsonKey(name: 'unacknowledged_total')
  final int? unacknowledgedTotal;

  /// Next page number, or null on the last page.
  @JsonKey(name: 'next_page')
  final int? nextPage;
  @JsonKey(name: 'prev_page')
  final int? prevPage;

  /// Whether more items remain (cursor pagination).
  @JsonKey(name: 'has_more')
  final bool? hasMore;

  /// Opaque cursor for the next page, or null when exhausted.
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;

  Map<String, Object?> toJson() => _$ListMetaToJson(this);
}
