// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_eta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StopEta _$StopEtaFromJson(Map<String, dynamic> json) => StopEta(
  shipmentId: json['shipment_id'] as String,
  sequence: (json['sequence'] as num).toInt(),
  etaAt: json['eta_at'] == null
      ? null
      : DateTime.parse(json['eta_at'] as String),
  etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
);

Map<String, dynamic> _$StopEtaToJson(StopEta instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'sequence': instance.sequence,
  'eta_at': instance.etaAt?.toIso8601String(),
  'eta_minutes': instance.etaMinutes,
};
