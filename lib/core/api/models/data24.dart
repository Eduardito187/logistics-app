// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'outbox_status.dart';

part 'data24.g.dart';

@JsonSerializable()
class Data24 {
  const Data24({required this.id, required this.status});

  factory Data24.fromJson(Map<String, Object?> json) => _$Data24FromJson(json);

  final String id;
  final OutboxStatus status;

  Map<String, Object?> toJson() => _$Data24ToJson(this);
}
