// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_channels_payments_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostChannelsPaymentsResponse _$PostChannelsPaymentsResponseFromJson(
  Map<String, dynamic> json,
) => PostChannelsPaymentsResponse(
  data: CommercePayment.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostChannelsPaymentsResponseToJson(
  PostChannelsPaymentsResponse instance,
) => <String, dynamic>{'data': instance.data};
