// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_trip_state.dart';

part 'post_app_carriers_trips_trip_id_start_response.g.dart';

@JsonSerializable()
class PostAppCarriersTripsTripIdStartResponse {
  const PostAppCarriersTripsTripIdStartResponse({required this.data});

  factory PostAppCarriersTripsTripIdStartResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppCarriersTripsTripIdStartResponseFromJson(json);

  final CarrierTripState data;

  Map<String, Object?> toJson() =>
      _$PostAppCarriersTripsTripIdStartResponseToJson(this);
}
