// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'ping_batch_result_envelope_data_source.dart';
import 'results2.dart';

part 'ping_batch_result_envelope_data.g.dart';

@JsonSerializable()
class PingBatchResultEnvelopeData {
  const PingBatchResultEnvelopeData({
    required this.accepted,
    required this.vehicleId,
    required this.source,
    required this.count,
    required this.acceptedCount,
    required this.duplicateCount,
    required this.rejectedCount,
    required this.results,
    this.buffered,
  });

  factory PingBatchResultEnvelopeData.fromJson(Map<String, Object?> json) =>
      _$PingBatchResultEnvelopeDataFromJson(json);

  final bool accepted;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final PingBatchResultEnvelopeDataSource source;
  final int count;
  @JsonKey(name: 'accepted_count')
  final int acceptedCount;
  @JsonKey(name: 'duplicate_count')
  final int duplicateCount;
  @JsonKey(name: 'rejected_count')
  final int rejectedCount;

  /// Present (true) only when the batch was queued for asynchronous persistence (TELEMETRY_INGEST_MODE=buffered). In that mode every well-formed fix is reported as accepted and duplicate_count is 0; duplicates are still discarded when persisted.
  final bool? buffered;
  final List<Results2> results;

  Map<String, Object?> toJson() => _$PingBatchResultEnvelopeDataToJson(this);
}
