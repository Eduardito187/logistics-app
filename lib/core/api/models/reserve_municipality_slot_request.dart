// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reserve_municipality_slot_request.g.dart';

@JsonSerializable()
class ReserveMunicipalitySlotRequest {
  const ReserveMunicipalitySlotRequest({
    required this.shipmentId,
    required this.date,
    required this.windowStart,
    required this.windowEnd,
    this.municipalityId,
    this.latitude,
    this.longitude,
  });

  factory ReserveMunicipalitySlotRequest.fromJson(Map<String, Object?> json) =>
      _$ReserveMunicipalitySlotRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final DateTime date;
  @JsonKey(name: 'window_start')
  final String windowStart;
  @JsonKey(name: 'window_end')
  final String windowEnd;
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;
  final num? latitude;
  final num? longitude;

  Map<String, Object?> toJson() => _$ReserveMunicipalitySlotRequestToJson(this);
}
