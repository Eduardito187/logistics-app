// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_document.dart';
import 'list_meta.dart';

part 'get_app_staff_user_id_documents_response.g.dart';

@JsonSerializable()
class GetAppStaffUserIdDocumentsResponse {
  const GetAppStaffUserIdDocumentsResponse({
    required this.data,
    required this.meta,
  });

  factory GetAppStaffUserIdDocumentsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppStaffUserIdDocumentsResponseFromJson(json);

  final List<StaffDocument> data;
  final ListMeta meta;

  Map<String, Object?> toJson() =>
      _$GetAppStaffUserIdDocumentsResponseToJson(this);
}
