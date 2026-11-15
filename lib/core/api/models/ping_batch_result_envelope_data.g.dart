// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ping_batch_result_envelope_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PingBatchResultEnvelopeData _$PingBatchResultEnvelopeDataFromJson(
  Map<String, dynamic> json,
) => PingBatchResultEnvelopeData(
  accepted: json['accepted'] as bool,
  vehicleId: json['vehicle_id'] as String,
  source: PingBatchResultEnvelopeDataSource.fromJson(json['source'] as String),
  count: (json['count'] as num).toInt(),
  acceptedCount: (json['accepted_count'] as num).toInt(),
  duplicateCount: (json['duplicate_count'] as num).toInt(),
  rejectedCount: (json['rejected_count'] as num).toInt(),
  results: (json['results'] as List<dynamic>)
      .map((e) => Results2.fromJson(e as Map<String, dynamic>))
      .toList(),
  buffered: json['buffered'] as bool?,
);

Map<String, dynamic> _$PingBatchResultEnvelopeDataToJson(
  PingBatchResultEnvelopeData instance,
) => <String, dynamic>{
  'accepted': instance.accepted,
  'vehicle_id': instance.vehicleId,
  'source': instance.source,
  'count': instance.count,
  'accepted_count': instance.acceptedCount,
  'duplicate_count': instance.duplicateCount,
  'rejected_count': instance.rejectedCount,
  'buffered': instance.buffered,
  'results': instance.results,
};
