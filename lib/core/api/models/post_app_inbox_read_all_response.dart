// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mark_inbox_all_read_data.dart';

part 'post_app_inbox_read_all_response.g.dart';

@JsonSerializable()
class PostAppInboxReadAllResponse {
  const PostAppInboxReadAllResponse({this.data});

  factory PostAppInboxReadAllResponse.fromJson(Map<String, Object?> json) =>
      _$PostAppInboxReadAllResponseFromJson(json);

  final MarkInboxAllReadData? data;

  Map<String, Object?> toJson() => _$PostAppInboxReadAllResponseToJson(this);
}
