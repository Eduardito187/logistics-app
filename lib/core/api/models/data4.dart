// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'data4.g.dart';

@JsonSerializable()
class Data4 {
  const Data4({this.status, this.vehicleId, this.driverId, this.performedOn});

  factory Data4.fromJson(Map<String, Object?> json) => _$Data4FromJson(json);

  final String? status;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'performed_on')
  final DateTime? performedOn;

  Map<String, Object?> toJson() => _$Data4ToJson(this);
}
