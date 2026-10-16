// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_status.dart';

part 'data6.g.dart';

@JsonSerializable()
class Data6 {
  const Data6({this.status, this.vehicleId, this.newStatus});

  factory Data6.fromJson(Map<String, Object?> json) => _$Data6FromJson(json);

  final String? status;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'new_status')
  final VehicleStatus? newStatus;

  Map<String, Object?> toJson() => _$Data6ToJson(this);
}
