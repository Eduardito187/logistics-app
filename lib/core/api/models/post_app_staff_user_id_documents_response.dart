// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_document.dart';

part 'post_app_staff_user_id_documents_response.g.dart';

@JsonSerializable()
class PostAppStaffUserIdDocumentsResponse {
  const PostAppStaffUserIdDocumentsResponse({required this.data});

  factory PostAppStaffUserIdDocumentsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppStaffUserIdDocumentsResponseFromJson(json);

  final StaffDocument data;

  Map<String, Object?> toJson() =>
      _$PostAppStaffUserIdDocumentsResponseToJson(this);
}
