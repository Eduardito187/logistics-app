// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_live_fleet_positions_meta.g.dart';

@JsonSerializable()
class GetLiveFleetPositionsMeta {
  const GetLiveFleetPositionsMeta({this.count, this.since, this.serverTime});

  factory GetLiveFleetPositionsMeta.fromJson(Map<String, Object?> json) =>
      _$GetLiveFleetPositionsMetaFromJson(json);

  final int? count;
  final DateTime? since;
  @JsonKey(name: 'server_time')
  final DateTime? serverTime;

  Map<String, Object?> toJson() => _$GetLiveFleetPositionsMetaToJson(this);
}
