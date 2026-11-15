// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'checklist_template.dart';
import 'checklist_template_item.dart';
import 'vehicle_fitness.dart';

part 'data.g.dart';

@JsonSerializable()
class Data {
  const Data({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.active,
    required this.items,
    required this.criticalKeys,
    this.vehicleFitness,
  });

  factory Data.fromJson(Map<String, Object?> json) => _$DataFromJson(json);

  final String id;
  final String name;
  @JsonKey(name: 'vehicle_type')
  final String? vehicleType;
  final bool active;
  final List<ChecklistTemplateItem> items;
  @JsonKey(name: 'critical_keys')
  final List<String> criticalKeys;
  @JsonKey(name: 'vehicle_fitness')
  final VehicleFitness? vehicleFitness;

  Map<String, Object?> toJson() => _$DataToJson(this);
}
