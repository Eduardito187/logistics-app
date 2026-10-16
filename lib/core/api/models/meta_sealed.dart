// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'pagination_meta.dart';
import 'cursor_meta.dart';

part 'meta_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class MetaSealed {
  const MetaSealed();

  factory MetaSealed.fromJson(Map<String, dynamic> json) =>
      MetaSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension MetaSealedDeserializer on MetaSealed {
  static MetaSealed tryDeserialize(Map<String, dynamic> json) {
    try {
      return MetaSealedVariant1.fromJson(json);
    } catch (_) {}
    try {
      return MetaSealedPaginationMeta.fromJson(json);
    } catch (_) {}
    try {
      return MetaSealedCursorMeta.fromJson(json);
    } catch (_) {}

    throw FormatException(
      'Could not determine the correct type for MetaSealed from: $json',
    );
  }
}

@JsonSerializable()
class MetaSealedVariant1 extends MetaSealed {
  @override
  final int count;

  const MetaSealedVariant1({required this.count});

  factory MetaSealedVariant1.fromJson(Map<String, dynamic> json) =>
      _$MetaSealedVariant1FromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MetaSealedVariant1ToJson(this);
}

@JsonSerializable()
class MetaSealedPaginationMeta extends MetaSealed implements PaginationMeta {
  @override
  final int count;
  @override
  final int page;
  @override
  final int perPage;
  @override
  final int total;
  @override
  final int totalPages;
  @override
  final int? nextPage;
  @override
  final int? prevPage;

  const MetaSealedPaginationMeta({
    required this.count,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.nextPage,
    required this.prevPage,
  });

  factory MetaSealedPaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$MetaSealedPaginationMetaFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MetaSealedPaginationMetaToJson(this);
}

@JsonSerializable()
class MetaSealedCursorMeta extends MetaSealed implements CursorMeta {
  @override
  final int count;
  @override
  final int perPage;
  @override
  final bool hasMore;
  @override
  final String? nextCursor;

  const MetaSealedCursorMeta({
    required this.count,
    required this.perPage,
    required this.hasMore,
    required this.nextCursor,
  });

  factory MetaSealedCursorMeta.fromJson(Map<String, dynamic> json) =>
      _$MetaSealedCursorMetaFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MetaSealedCursorMetaToJson(this);
}
