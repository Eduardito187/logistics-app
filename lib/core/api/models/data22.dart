// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data22.g.dart';

@JsonSerializable()
class Data22 {
  const Data22({required this.notificationId, required this.status});

  factory Data22.fromJson(Map<String, Object?> json) => _$Data22FromJson(json);

  @JsonKey(name: 'notification_id')
  final String notificationId;
  final String status;

  Map<String, Object?> toJson() => _$Data22ToJson(this);
}
