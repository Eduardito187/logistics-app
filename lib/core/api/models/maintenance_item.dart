// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'maintenance_item.g.dart';

/// A maintenance line item (part + labor)
@JsonSerializable()
class MaintenanceItem {
  const MaintenanceItem({
    required this.description,
    required this.qty,
    required this.partCostCents,
    required this.laborCostCents,
  });

  factory MaintenanceItem.fromJson(Map<String, Object?> json) =>
      _$MaintenanceItemFromJson(json);

  final String description;
  final int qty;
  @JsonKey(name: 'part_cost_cents')
  final int partCostCents;
  @JsonKey(name: 'labor_cost_cents')
  final int laborCostCents;

  Map<String, Object?> toJson() => _$MaintenanceItemToJson(this);
}
