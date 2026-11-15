// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'send_staff_broadcast_data.dart';

part 'post_app_broadcasts_response.g.dart';

@JsonSerializable()
class PostAppBroadcastsResponse {
  const PostAppBroadcastsResponse({this.data});

  factory PostAppBroadcastsResponse.fromJson(Map<String, Object?> json) =>
      _$PostAppBroadcastsResponseFromJson(json);

  final SendStaffBroadcastData? data;

  Map<String, Object?> toJson() => _$PostAppBroadcastsResponseToJson(this);
}
