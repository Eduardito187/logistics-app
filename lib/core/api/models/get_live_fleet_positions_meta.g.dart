// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_live_fleet_positions_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetLiveFleetPositionsMeta _$GetLiveFleetPositionsMetaFromJson(
  Map<String, dynamic> json,
) => GetLiveFleetPositionsMeta(
  count: (json['count'] as num?)?.toInt(),
  since: json['since'] == null ? null : DateTime.parse(json['since'] as String),
  serverTime: json['server_time'] == null
      ? null
      : DateTime.parse(json['server_time'] as String),
);

Map<String, dynamic> _$GetLiveFleetPositionsMetaToJson(
  GetLiveFleetPositionsMeta instance,
) => <String, dynamic>{
  'count': instance.count,
  'since': instance.since?.toIso8601String(),
  'server_time': instance.serverTime?.toIso8601String(),
};
