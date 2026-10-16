// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_source.dart';
import 'status7.dart';

part 'data25.g.dart';

@JsonSerializable()
class Data25 {
  const Data25({
    required this.source,
    required this.externalId,
    required this.status,
  });

  factory Data25.fromJson(Map<String, Object?> json) => _$Data25FromJson(json);

  final OrderSource source;
  @JsonKey(name: 'external_id')
  final String externalId;
  final Status7 status;

  Map<String, Object?> toJson() => _$Data25ToJson(this);
}
