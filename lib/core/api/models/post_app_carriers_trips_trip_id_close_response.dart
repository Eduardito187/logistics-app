// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_trip_state.dart';

part 'post_app_carriers_trips_trip_id_close_response.g.dart';

@JsonSerializable()
class PostAppCarriersTripsTripIdCloseResponse {
  const PostAppCarriersTripsTripIdCloseResponse({required this.data});

  factory PostAppCarriersTripsTripIdCloseResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppCarriersTripsTripIdCloseResponseFromJson(json);

  final CarrierTripState data;

  Map<String, Object?> toJson() =>
      _$PostAppCarriersTripsTripIdCloseResponseToJson(this);
}
