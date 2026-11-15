// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_expiry.dart';
import 'vehicle_status.dart';

part 'vehicle.g.dart';

@JsonSerializable()
class Vehicle {
  const Vehicle({
    this.fitToDispatch,
    this.unfitSince,
    this.unfitReason,
    this.unfitItems,
    this.id,
    this.plate,
    this.capacityKg,
    this.capacityM3,
    this.homeBaseNodeId,
    this.status,
    this.documents,
  });

  factory Vehicle.fromJson(Map<String, Object?> json) =>
      _$VehicleFromJson(json);

  /// False while a failed critical pre-trip item is not cleared by a supervisor.
  @JsonKey(name: 'fit_to_dispatch')
  final bool? fitToDispatch;
  @JsonKey(name: 'unfit_since')
  final DateTime? unfitSince;
  @JsonKey(name: 'unfit_reason')
  final String? unfitReason;
  @JsonKey(name: 'unfit_items')
  final List<String>? unfitItems;
  final String? id;
  final String? plate;
  @JsonKey(name: 'capacity_kg')
  final int? capacityKg;
  @JsonKey(name: 'capacity_m3')
  final double? capacityM3;
  @JsonKey(name: 'home_base_node_id')
  final String? homeBaseNodeId;
  final VehicleStatus? status;
  final List<DocumentExpiry>? documents;

  Map<String, Object?> toJson() => _$VehicleToJson(this);
}
