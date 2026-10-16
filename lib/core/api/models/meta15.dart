// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'meta15.g.dart';

@JsonSerializable()
class Meta15 {
  const Meta15({
    required this.total,
    required this.page,
    required this.perPage,
    required this.lastPage,
  });

  factory Meta15.fromJson(Map<String, Object?> json) => _$Meta15FromJson(json);

  final int total;
  final int page;
  @JsonKey(name: 'per_page')
  final int perPage;
  @JsonKey(name: 'last_page')
  final int lastPage;

  Map<String, Object?> toJson() => _$Meta15ToJson(this);
}
