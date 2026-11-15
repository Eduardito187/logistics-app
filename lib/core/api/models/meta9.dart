// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'meta9.g.dart';

@JsonSerializable()
class Meta9 {
  const Meta9({
    required this.total,
    required this.page,
    required this.perPage,
    required this.lastPage,
  });

  factory Meta9.fromJson(Map<String, Object?> json) => _$Meta9FromJson(json);

  final int total;
  final int page;
  @JsonKey(name: 'per_page')
  final int perPage;
  @JsonKey(name: 'last_page')
  final int lastPage;

  Map<String, Object?> toJson() => _$Meta9ToJson(this);
}
