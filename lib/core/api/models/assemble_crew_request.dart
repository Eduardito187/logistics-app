// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'assemble_crew_request.g.dart';

@JsonSerializable()
class AssembleCrewRequest {
  const AssembleCrewRequest({
    required this.driverId,
    required this.vehicleId,
    required this.assembledFor,
    this.helperIds,
  });

  factory AssembleCrewRequest.fromJson(Map<String, Object?> json) =>
      _$AssembleCrewRequestFromJson(json);

  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'helper_ids')
  final List<String>? helperIds;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'assembled_for')
  final DateTime assembledFor;

  Map<String, Object?> toJson() => _$AssembleCrewRequestToJson(this);
}
