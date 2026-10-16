// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_expiry.dart';
import 'vehicle_status.dart';

part 'register_vehicle_request.g.dart';

@JsonSerializable()
class RegisterVehicleRequest {
  const RegisterVehicleRequest({
    required this.plate,
    required this.capacityKg,
    required this.capacityM3,
    required this.homeBaseNodeId,
    this.status,
    this.documents,
  });

  factory RegisterVehicleRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterVehicleRequestFromJson(json);

  final String plate;
  @JsonKey(name: 'capacity_kg')
  final int capacityKg;
  @JsonKey(name: 'capacity_m3')
  final num capacityM3;
  @JsonKey(name: 'home_base_node_id')
  final String homeBaseNodeId;
  final VehicleStatus? status;
  final List<DocumentExpiry>? documents;

  Map<String, Object?> toJson() => _$RegisterVehicleRequestToJson(this);
}
