// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'trip_sequence_stop.g.dart';

@JsonSerializable()
class TripSequenceStop {
  const TripSequenceStop({
    required this.shipmentId,
    required this.sequence,
    required this.withinWindow,
    this.etaAt,
  });

  factory TripSequenceStop.fromJson(Map<String, Object?> json) =>
      _$TripSequenceStopFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final int sequence;

  /// Null only for a shipment without location.
  @JsonKey(name: 'eta_at')
  final DateTime? etaAt;
  @JsonKey(name: 'within_window')
  final bool withinWindow;

  Map<String, Object?> toJson() => _$TripSequenceStopToJson(this);
}
