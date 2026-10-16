// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_labels_public_keys_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppLabelsPublicKeysResponse _$GetAppLabelsPublicKeysResponseFromJson(
  Map<String, dynamic> json,
) => GetAppLabelsPublicKeysResponse(
  data: PublicKeyBundle.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppLabelsPublicKeysResponseToJson(
  GetAppLabelsPublicKeysResponse instance,
) => <String, dynamic>{'data': instance.data};
