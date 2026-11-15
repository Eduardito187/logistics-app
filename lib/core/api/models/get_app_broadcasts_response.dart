// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_broadcast.dart';
import 'list_meta.dart';

part 'get_app_broadcasts_response.g.dart';

@JsonSerializable()
class GetAppBroadcastsResponse {
  const GetAppBroadcastsResponse({required this.data, required this.meta});

  factory GetAppBroadcastsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppBroadcastsResponseFromJson(json);

  final List<StaffBroadcast> data;
  final ListMeta meta;

  Map<String, Object?> toJson() => _$GetAppBroadcastsResponseToJson(this);
}
