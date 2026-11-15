// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'daily_kpis_scope.dart';
import 'failed_by_reason.dart';

part 'daily_kpis.g.dart';

@JsonSerializable()
class DailyKpis {
  const DailyKpis({
    required this.date,
    required this.scope,
    required this.deliveriesTotal,
    required this.delivered,
    required this.failed,
    required this.rescheduled,
    required this.pending,
    required this.onTimeRate,
    required this.firstAttemptSuccessRate,
    required this.avgStopMinutes,
    required this.km,
    required this.failedByReason,
    required this.generatedAt,
  });

  factory DailyKpis.fromJson(Map<String, Object?> json) =>
      _$DailyKpisFromJson(json);

  final DateTime date;
  final DailyKpisScope scope;
  @JsonKey(name: 'deliveries_total')
  final int deliveriesTotal;
  final int delivered;
  final int failed;
  final int rescheduled;
  final int pending;

  /// 0..1, closed before the promised window end (La Paz).
  @JsonKey(name: 'on_time_rate')
  final num? onTimeRate;

  /// 0..1 over delivered+failed.
  @JsonKey(name: 'first_attempt_success_rate')
  final num? firstAttemptSuccessRate;

  /// Arrival to close; null until stops record arrived_at.
  @JsonKey(name: 'avg_stop_minutes')
  final num? avgStopMinutes;

  /// Odometer delta of the day's departures; null without readings or for node scope.
  final int? km;
  @JsonKey(name: 'failed_by_reason')
  final List<FailedByReason> failedByReason;
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;

  Map<String, Object?> toJson() => _$DailyKpisToJson(this);
}
