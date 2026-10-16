// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'planned_stop.g.dart';

@JsonSerializable()
class PlannedStop {
  const PlannedStop({
    required this.id,
    required this.shipmentId,
    required this.sequence,
    required this.loadOrder,
    this.etaAt,
    this.etaMinutes,
    this.lane,
  });

  factory PlannedStop.fromJson(Map<String, Object?> json) =>
      _$PlannedStopFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;

  /// Delivery position, 1-based
  final int sequence;
  @JsonKey(name: 'eta_at')
  final DateTime? etaAt;

  /// Minutes from depot departure
  @JsonKey(name: 'eta_minutes')
  final int? etaMinutes;

  /// Load lane label
  final String? lane;

  /// Loading order (reverse of delivery)
  @JsonKey(name: 'load_order')
  final int loadOrder;

  Map<String, Object?> toJson() => _$PlannedStopToJson(this);
}
