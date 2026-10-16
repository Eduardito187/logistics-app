// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plan_status.dart';
import 'stop_eta.dart';

part 'data6.g.dart';

@JsonSerializable()
class Data6 {
  const Data6({
    required this.planId,
    required this.status,
    required this.stops,
  });

  factory Data6.fromJson(Map<String, Object?> json) => _$Data6FromJson(json);

  @JsonKey(name: 'plan_id')
  final String planId;
  final PlanStatus status;
  final List<StopEta> stops;

  Map<String, Object?> toJson() => _$Data6ToJson(this);
}
