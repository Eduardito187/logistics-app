// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status5.dart';

part 'data20.g.dart';

@JsonSerializable()
class Data20 {
  const Data20({required this.eventId, required this.status});

  factory Data20.fromJson(Map<String, Object?> json) => _$Data20FromJson(json);

  @JsonKey(name: 'event_id')
  final String eventId;
  final Status5 status;

  Map<String, Object?> toJson() => _$Data20ToJson(this);
}
