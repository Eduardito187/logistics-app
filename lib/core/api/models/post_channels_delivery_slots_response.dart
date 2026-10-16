// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'reserved_delivery_slot.dart';

part 'post_channels_delivery_slots_response.g.dart';

@JsonSerializable()
class PostChannelsDeliverySlotsResponse {
  const PostChannelsDeliverySlotsResponse({this.data});

  factory PostChannelsDeliverySlotsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostChannelsDeliverySlotsResponseFromJson(json);

  final ReservedDeliverySlot? data;

  Map<String, Object?> toJson() =>
      _$PostChannelsDeliverySlotsResponseToJson(this);
}
