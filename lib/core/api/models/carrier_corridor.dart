// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'corridor_type.dart';
import 'vehicle_class.dart';

part 'carrier_corridor.g.dart';

@JsonSerializable()
class CarrierCorridor {
  const CarrierCorridor({
    required this.from,
    required this.to,
    required this.fromLabel,
    required this.toLabel,
    required this.corridorType,
    required this.vehicleClasses,
  });

  factory CarrierCorridor.fromJson(Map<String, Object?> json) =>
      _$CarrierCorridorFromJson(json);

  /// Exact corridor origin slug as stored in the tariff
  final String from;
  final String to;
  @JsonKey(name: 'from_label')
  final String fromLabel;
  @JsonKey(name: 'to_label')
  final String toLabel;
  @JsonKey(name: 'corridor_type')
  final CorridorType corridorType;
  @JsonKey(name: 'vehicle_classes')
  final List<VehicleClass> vehicleClasses;

  Map<String, Object?> toJson() => _$CarrierCorridorToJson(this);
}
