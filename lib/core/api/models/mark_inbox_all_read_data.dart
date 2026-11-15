// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'mark_inbox_all_read_data.g.dart';

@JsonSerializable()
class MarkInboxAllReadData {
  const MarkInboxAllReadData({this.marked});

  factory MarkInboxAllReadData.fromJson(Map<String, Object?> json) =>
      _$MarkInboxAllReadDataFromJson(json);

  final int? marked;

  Map<String, Object?> toJson() => _$MarkInboxAllReadDataToJson(this);
}
