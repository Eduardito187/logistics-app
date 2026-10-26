// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'asn_appointment.g.dart';

@JsonSerializable()
class AsnAppointment {
  const AsnAppointment({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.timeSlot,
  });

  factory AsnAppointment.fromJson(Map<String, Object?> json) =>
      _$AsnAppointmentFromJson(json);

  final DateTime date;

  /// Window start time (HH:MM).
  @JsonKey(name: 'start_time')
  final String startTime;

  /// Window end time (HH:MM).
  @JsonKey(name: 'end_time')
  final String endTime;

  /// Time slot as HH:MM-HH:MM.
  @JsonKey(name: 'time_slot')
  final String timeSlot;

  Map<String, Object?> toJson() => _$AsnAppointmentToJson(this);
}
