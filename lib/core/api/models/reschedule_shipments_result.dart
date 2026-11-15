// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'failed.dart';
import 'shipments2.dart';
import 'skipped.dart';

part 'reschedule_shipments_result.g.dart';

@JsonSerializable()
class RescheduleShipmentsResult {
  const RescheduleShipmentsResult({
    this.applied,
    this.newDate,
    this.windowStart,
    this.windowEnd,
    this.count,
    this.skippedCount,
    this.shipments,
    this.skipped,
    this.failed,
  });

  factory RescheduleShipmentsResult.fromJson(Map<String, Object?> json) =>
      _$RescheduleShipmentsResultFromJson(json);

  final bool? applied;
  @JsonKey(name: 'new_date')
  final DateTime? newDate;
  @JsonKey(name: 'window_start')
  final String? windowStart;
  @JsonKey(name: 'window_end')
  final String? windowEnd;

  /// Pedidos alcanzados (preview) o reprogramados (aplicado)
  final int? count;
  @JsonKey(name: 'skipped_count')
  final int? skippedCount;
  final List<Shipments2>? shipments;
  final List<Skipped>? skipped;

  /// Solo al aplicar; pedidos que no se pudieron reprogramar, con el motivo
  final List<Failed>? failed;

  Map<String, Object?> toJson() => _$RescheduleShipmentsResultToJson(this);
}
