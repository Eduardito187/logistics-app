// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_channels_promises_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostChannelsPromisesResponse _$PostChannelsPromisesResponseFromJson(
  Map<String, dynamic> json,
) => PostChannelsPromisesResponse(
  data: json['data'] == null
      ? null
      : QuotedPromise.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostChannelsPromisesResponseToJson(
  PostChannelsPromisesResponse instance,
) => <String, dynamic>{'data': instance.data};
