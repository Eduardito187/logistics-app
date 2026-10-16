// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'record_service_done_request.g.dart';

@JsonSerializable()
class RecordServiceDoneRequest {
  const RecordServiceDoneRequest({this.odometerKm});

  factory RecordServiceDoneRequest.fromJson(Map<String, Object?> json) =>
      _$RecordServiceDoneRequestFromJson(json);

  @JsonKey(name: 'odometer_km')
  final int? odometerKm;

  Map<String, Object?> toJson() => _$RecordServiceDoneRequestToJson(this);
}
