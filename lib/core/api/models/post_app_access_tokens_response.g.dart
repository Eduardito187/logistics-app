// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_access_tokens_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppAccessTokensResponse _$PostAppAccessTokensResponseFromJson(
  Map<String, dynamic> json,
) => PostAppAccessTokensResponse(
  data: IssuedToken.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostAppAccessTokensResponseToJson(
  PostAppAccessTokensResponse instance,
) => <String, dynamic>{'data': instance.data};
