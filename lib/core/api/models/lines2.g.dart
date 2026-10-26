// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lines2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lines2 _$Lines2FromJson(Map<String, dynamic> json) => Lines2(
  sku: json['sku'] as String,
  accepted: (json['accepted'] as num).toInt(),
  rejected: (json['rejected'] as num).toInt(),
  damaged: (json['damaged'] as num).toInt(),
  qcOutcome: QcOutcome.fromJson(json['qc_outcome'] as String),
);

Map<String, dynamic> _$Lines2ToJson(Lines2 instance) => <String, dynamic>{
  'sku': instance.sku,
  'accepted': instance.accepted,
  'rejected': instance.rejected,
  'damaged': instance.damaged,
  'qc_outcome': instance.qcOutcome,
};
