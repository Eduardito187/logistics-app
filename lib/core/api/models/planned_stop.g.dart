// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_stop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlannedStop _$PlannedStopFromJson(Map<String, dynamic> json) => PlannedStop(
  id: json['id'] as String,
  shipmentId: json['shipment_id'] as String,
  sequence: (json['sequence'] as num).toInt(),
  loadOrder: (json['load_order'] as num).toInt(),
  etaAt: json['eta_at'] == null
      ? null
      : DateTime.parse(json['eta_at'] as String),
  etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
  lane: json['lane'] as String?,
);

Map<String, dynamic> _$PlannedStopToJson(PlannedStop instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shipment_id': instance.shipmentId,
      'sequence': instance.sequence,
      'eta_at': instance.etaAt?.toIso8601String(),
      'eta_minutes': instance.etaMinutes,
      'lane': instance.lane,
      'load_order': instance.loadOrder,
    };
