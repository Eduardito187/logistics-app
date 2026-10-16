// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_status.dart';

part 'data5.g.dart';

@JsonSerializable()
class Data5 {
  const Data5({this.status, this.vehicleId, this.newStatus});

  factory Data5.fromJson(Map<String, Object?> json) => _$Data5FromJson(json);

  final String? status;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'new_status')
  final VehicleStatus? newStatus;

  Map<String, Object?> toJson() => _$Data5ToJson(this);
}
