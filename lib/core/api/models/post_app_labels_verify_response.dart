// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'label_verification.dart';

part 'post_app_labels_verify_response.g.dart';

@JsonSerializable()
class PostAppLabelsVerifyResponse {
  const PostAppLabelsVerifyResponse({required this.data});

  factory PostAppLabelsVerifyResponse.fromJson(Map<String, Object?> json) =>
      _$PostAppLabelsVerifyResponseFromJson(json);

  final LabelVerification data;

  Map<String, Object?> toJson() => _$PostAppLabelsVerifyResponseToJson(this);
}
