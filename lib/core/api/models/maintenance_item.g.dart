// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceItem _$MaintenanceItemFromJson(Map<String, dynamic> json) =>
    MaintenanceItem(
      description: json['description'] as String,
      qty: (json['qty'] as num).toInt(),
      partCostCents: (json['part_cost_cents'] as num).toInt(),
      laborCostCents: (json['labor_cost_cents'] as num).toInt(),
    );

Map<String, dynamic> _$MaintenanceItemToJson(MaintenanceItem instance) =>
    <String, dynamic>{
      'description': instance.description,
      'qty': instance.qty,
      'part_cost_cents': instance.partCostCents,
      'labor_cost_cents': instance.laborCostCents,
    };
