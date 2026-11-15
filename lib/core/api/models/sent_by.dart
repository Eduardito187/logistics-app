// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sent_by.g.dart';

@JsonSerializable()
class SentBy {
  const SentBy({this.id, this.name});

  factory SentBy.fromJson(Map<String, Object?> json) => _$SentByFromJson(json);

  final int? id;
  final String? name;

  Map<String, Object?> toJson() => _$SentByToJson(this);
}
