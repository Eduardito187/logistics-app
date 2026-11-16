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
    this.shiftStartsAt,
    this.shiftEndsAt,
    this.replace,
  });

  factory AssembleCrewRequest.fromJson(Map<String, Object?> json) =>
      _$AssembleCrewRequestFromJson(json);

  @JsonKey(name: 'driver_id')
  final String driverId;

  /// Ausente = conserva los ayudantes de la tripulación anterior; una lista (aun vacía) los reemplaza.
  @JsonKey(name: 'helper_ids')
  final List<String>? helperIds;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'assembled_for')
  final DateTime assembledFor;
  @JsonKey(name: 'shift_starts_at')
  final DateTime? shiftStartsAt;
  @JsonKey(name: 'shift_ends_at')
  final DateTime? shiftEndsAt;

  /// Confirma quitarle el camión al chofer que ya lo tiene ese día (ante un 409).
  final bool? replace;

  Map<String, Object?> toJson() => _$AssembleCrewRequestToJson(this);
}
