// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data2.g.dart';

@JsonSerializable()
class Data2 {
  const Data2({this.status, this.driverId, this.vehicleId, this.assembledFor});

  factory Data2.fromJson(Map<String, Object?> json) => _$Data2FromJson(json);

  final String? status;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'assembled_for')
  final DateTime? assembledFor;

  Map<String, Object?> toJson() => _$Data2ToJson(this);
}
