// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'odometer_reading_source.dart';

part 'odometer_reading.g.dart';

/// An odometer reading of a vehicle
@JsonSerializable()
class OdometerReading {
  const OdometerReading({
    required this.id,
    required this.vehicleId,
    required this.km,
    required this.source,
    required this.readAt,
    this.note,
  });

  factory OdometerReading.fromJson(Map<String, Object?> json) =>
      _$OdometerReadingFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final int km;
  final OdometerReadingSource source;
  @JsonKey(name: 'read_at')
  final DateTime readAt;
  final String? note;

  Map<String, Object?> toJson() => _$OdometerReadingToJson(this);
}
