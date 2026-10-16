// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status4.dart';

part 'data19.g.dart';

@JsonSerializable()
class Data19 {
  const Data19({required this.eventId, required this.status});

  factory Data19.fromJson(Map<String, Object?> json) => _$Data19FromJson(json);

  @JsonKey(name: 'event_id')
  final String eventId;
  final Status4 status;

  Map<String, Object?> toJson() => _$Data19ToJson(this);
}
