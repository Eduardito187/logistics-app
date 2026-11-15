// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_sequence_stop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripSequenceStop _$TripSequenceStopFromJson(Map<String, dynamic> json) =>
    TripSequenceStop(
      shipmentId: json['shipment_id'] as String,
      sequence: (json['sequence'] as num).toInt(),
      withinWindow: json['within_window'] as bool,
      etaAt: json['eta_at'] == null
          ? null
          : DateTime.parse(json['eta_at'] as String),
    );

Map<String, dynamic> _$TripSequenceStopToJson(TripSequenceStop instance) =>
    <String, dynamic>{
      'shipment_id': instance.shipmentId,
      'sequence': instance.sequence,
      'eta_at': instance.etaAt?.toIso8601String(),
      'within_window': instance.withinWindow,
    };
