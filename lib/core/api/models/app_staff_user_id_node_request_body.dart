// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_staff_user_id_node_request_body.g.dart';

@JsonSerializable()
class AppStaffUserIdNodeRequestBody {
  const AppStaffUserIdNodeRequestBody({required this.nodeId});

  factory AppStaffUserIdNodeRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppStaffUserIdNodeRequestBodyFromJson(json);

  @JsonKey(name: 'node_id')
  final String? nodeId;

  Map<String, Object?> toJson() => _$AppStaffUserIdNodeRequestBodyToJson(this);
}
