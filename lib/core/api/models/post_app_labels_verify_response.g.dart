// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_labels_verify_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppLabelsVerifyResponse _$PostAppLabelsVerifyResponseFromJson(
  Map<String, dynamic> json,
) => PostAppLabelsVerifyResponse(
  data: LabelVerification.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostAppLabelsVerifyResponseToJson(
  PostAppLabelsVerifyResponse instance,
) => <String, dynamic>{'data': instance.data};
