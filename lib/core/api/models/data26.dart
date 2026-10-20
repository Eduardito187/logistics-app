// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_source.dart';
import 'status8.dart';

part 'data26.g.dart';

@JsonSerializable()
class Data26 {
  const Data26({
    required this.source,
    required this.externalId,
    required this.status,
  });

  factory Data26.fromJson(Map<String, Object?> json) => _$Data26FromJson(json);

  final OrderSource source;
  @JsonKey(name: 'external_id')
  final String externalId;
  final Status8 status;

  Map<String, Object?> toJson() => _$Data26ToJson(this);
}
