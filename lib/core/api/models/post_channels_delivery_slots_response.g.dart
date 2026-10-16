// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_channels_delivery_slots_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostChannelsDeliverySlotsResponse _$PostChannelsDeliverySlotsResponseFromJson(
  Map<String, dynamic> json,
) => PostChannelsDeliverySlotsResponse(
  data: json['data'] == null
      ? null
      : ReservedDeliverySlot.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostChannelsDeliverySlotsResponseToJson(
  PostChannelsDeliverySlotsResponse instance,
) => <String, dynamic>{'data': instance.data};
