// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_inbox_item.dart';
import 'list_meta.dart';

part 'get_app_inbox_response.g.dart';

@JsonSerializable()
class GetAppInboxResponse {
  const GetAppInboxResponse({required this.data, required this.meta});

  factory GetAppInboxResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppInboxResponseFromJson(json);

  final List<StaffInboxItem> data;
  final ListMeta meta;

  Map<String, Object?> toJson() => _$GetAppInboxResponseToJson(this);
}
