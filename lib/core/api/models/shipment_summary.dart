// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment_status_counts.dart';

part 'shipment_summary.g.dart';

@JsonSerializable()
class ShipmentSummary {
  const ShipmentSummary({
    required this.dateFrom,
    required this.dateTo,
    required this.total,
    required this.byStatus,
    required this.byExecutionStatus,
    required this.activePlans,
    required this.openAlerts,
    required this.unitsTotal,
    required this.generatedAt,
  });

  factory ShipmentSummary.fromJson(Map<String, Object?> json) =>
      _$ShipmentSummaryFromJson(json);

  @JsonKey(name: 'date_from')
  final DateTime? dateFrom;
  @JsonKey(name: 'date_to')
  final DateTime? dateTo;
  final int total;
  @JsonKey(name: 'by_status')
  final ShipmentStatusCounts byStatus;
  @JsonKey(name: 'by_execution_status')
  final Map<String, int> byExecutionStatus;

  /// PUBLISHED plans in the period (default today).
  @JsonKey(name: 'active_plans')
  final int activePlans;

  /// Unacknowledged telemetry alerts in the period.
  @JsonKey(name: 'open_alerts')
  final int openAlerts;
  @JsonKey(name: 'units_total')
  final int unitsTotal;
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;

  Map<String, Object?> toJson() => _$ShipmentSummaryToJson(this);
}
