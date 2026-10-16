// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'municipality_slot.dart';
import 'meta_sealed.dart';

part 'get_channels_promises_delivery_response.g.dart';

@JsonSerializable()
class GetChannelsPromisesDeliveryResponse {
  const GetChannelsPromisesDeliveryResponse({required this.data, this.meta});

  factory GetChannelsPromisesDeliveryResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsPromisesDeliveryResponseFromJson(json);

  final List<MunicipalitySlot> data;
  final MetaSealed? meta;

  Map<String, Object?> toJson() =>
      _$GetChannelsPromisesDeliveryResponseToJson(this);
}
