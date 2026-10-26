// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'schedule_asn_request.g.dart';

@JsonSerializable()
class ScheduleAsnRequest {
  const ScheduleAsnRequest({
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleAsnRequest.fromJson(Map<String, Object?> json) =>
      _$ScheduleAsnRequestFromJson(json);

  @JsonKey(name: 'appointment_date')
  final DateTime appointmentDate;

  /// Window start time (HH:MM).
  @JsonKey(name: 'start_time')
  final String startTime;

  /// Window end time (HH:MM).
  @JsonKey(name: 'end_time')
  final String endTime;

  Map<String, Object?> toJson() => _$ScheduleAsnRequestToJson(this);
}
