// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_access_tokens_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppAccessTokensResponse _$GetAppAccessTokensResponseFromJson(
  Map<String, dynamic> json,
) => GetAppAccessTokensResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => IntegrationToken.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppAccessTokensResponseToJson(
  GetAppAccessTokensResponse instance,
) => <String, dynamic>{'data': instance.data};
