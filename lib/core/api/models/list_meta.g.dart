// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListMeta _$ListMetaFromJson(Map<String, dynamic> json) => ListMeta(
  count: (json['count'] as num).toInt(),
  anchor: json['anchor'] == null
      ? null
      : TripCandidateAnchor.fromJson(json['anchor'] as Map<String, dynamic>),
  capacity: json['capacity'] == null
      ? null
      : TripCapacity.fromJson(json['capacity'] as Map<String, dynamic>),
  page: (json['page'] as num?)?.toInt(),
  perPage: (json['per_page'] as num?)?.toInt(),
  total: (json['total'] as num?)?.toInt(),
  totalPages: (json['total_pages'] as num?)?.toInt(),
  unread: (json['unread'] as num?)?.toInt(),
  unreadCount: (json['unread_count'] as num?)?.toInt(),
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  dateTo: json['date_to'] == null
      ? null
      : DateTime.parse(json['date_to'] as String),
  countByStatus: (json['count_by_status'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toInt()),
  ),
  unacknowledgedTotal: (json['unacknowledged_total'] as num?)?.toInt(),
  nextPage: (json['next_page'] as num?)?.toInt(),
  prevPage: (json['prev_page'] as num?)?.toInt(),
  hasMore: json['has_more'] as bool?,
  nextCursor: json['next_cursor'] as String?,
);

Map<String, dynamic> _$ListMetaToJson(ListMeta instance) => <String, dynamic>{
  'anchor': instance.anchor,
  'capacity': instance.capacity,
  'count': instance.count,
  'page': instance.page,
  'per_page': instance.perPage,
  'total': instance.total,
  'total_pages': instance.totalPages,
  'unread': instance.unread,
  'unread_count': instance.unreadCount,
  'date': instance.date?.toIso8601String(),
  'date_to': instance.dateTo?.toIso8601String(),
  'count_by_status': instance.countByStatus,
  'unacknowledged_total': instance.unacknowledgedTotal,
  'next_page': instance.nextPage,
  'prev_page': instance.prevPage,
  'has_more': instance.hasMore,
  'next_cursor': instance.nextCursor,
};
