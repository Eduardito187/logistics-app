// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data3.g.dart';

@JsonSerializable()
class Data3 {
  const Data3({this.status, this.driverId, this.vehicleId, this.assembledFor});

  factory Data3.fromJson(Map<String, Object?> json) => _$Data3FromJson(json);

  final String? status;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'assembled_for')
  final DateTime? assembledFor;

  Map<String, Object?> toJson() => _$Data3ToJson(this);
}
