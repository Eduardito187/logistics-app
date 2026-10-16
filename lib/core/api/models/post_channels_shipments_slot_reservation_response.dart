// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'reserved_municipality_slot.dart';

part 'post_channels_shipments_slot_reservation_response.g.dart';

@JsonSerializable()
class PostChannelsShipmentsSlotReservationResponse {
  const PostChannelsShipmentsSlotReservationResponse({required this.data});

  factory PostChannelsShipmentsSlotReservationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostChannelsShipmentsSlotReservationResponseFromJson(json);

  final ReservedMunicipalitySlot data;

  Map<String, Object?> toJson() =>
      _$PostChannelsShipmentsSlotReservationResponseToJson(this);
}
