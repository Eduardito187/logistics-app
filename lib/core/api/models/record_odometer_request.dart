// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'record_odometer_request_source.dart';

part 'record_odometer_request.g.dart';

@JsonSerializable()
class RecordOdometerRequest {
  const RecordOdometerRequest({
    required this.vehicleId,
    required this.km,
    required this.source,
    required this.readAt,
    this.note,
  });

  factory RecordOdometerRequest.fromJson(Map<String, Object?> json) =>
      _$RecordOdometerRequestFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final int km;
  final RecordOdometerRequestSource source;
  @JsonKey(name: 'read_at')
  final DateTime readAt;
  final String? note;

  Map<String, Object?> toJson() => _$RecordOdometerRequestToJson(this);
}
