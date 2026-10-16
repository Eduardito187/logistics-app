// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'rate_carrier_request.g.dart';

@JsonSerializable()
class RateCarrierRequest {
  const RateCarrierRequest({required this.rating});

  factory RateCarrierRequest.fromJson(Map<String, Object?> json) =>
      _$RateCarrierRequestFromJson(json);

  final int rating;

  Map<String, Object?> toJson() => _$RateCarrierRequestToJson(this);
}
