// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'meta.g.dart';

@JsonSerializable()
class Meta {
  const Meta({required this.date, required this.count});

  factory Meta.fromJson(Map<String, Object?> json) => _$MetaFromJson(json);

  final DateTime date;
  final int count;

  Map<String, Object?> toJson() => _$MetaToJson(this);
}
