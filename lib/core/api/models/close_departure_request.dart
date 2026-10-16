// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'close_departure_request.g.dart';

@JsonSerializable()
class CloseDepartureRequest {
  const CloseDepartureRequest({
    required this.odometerInKm,
    required this.returnedAt,
  });

  factory CloseDepartureRequest.fromJson(Map<String, Object?> json) =>
      _$CloseDepartureRequestFromJson(json);

  @JsonKey(name: 'odometer_in_km')
  final int odometerInKm;
  @JsonKey(name: 'returned_at')
  final DateTime returnedAt;

  Map<String, Object?> toJson() => _$CloseDepartureRequestToJson(this);
}
