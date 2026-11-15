// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentSummary _$ShipmentSummaryFromJson(Map<String, dynamic> json) =>
    ShipmentSummary(
      dateFrom: json['date_from'] == null
          ? null
          : DateTime.parse(json['date_from'] as String),
      dateTo: json['date_to'] == null
          ? null
          : DateTime.parse(json['date_to'] as String),
      total: (json['total'] as num).toInt(),
      byStatus: Map<String, int>.from(json['by_status'] as Map),
      byExecutionStatus: Map<String, int>.from(
        json['by_execution_status'] as Map,
      ),
      activePlans: (json['active_plans'] as num).toInt(),
      openAlerts: (json['open_alerts'] as num).toInt(),
      unitsTotal: (json['units_total'] as num).toInt(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );

Map<String, dynamic> _$ShipmentSummaryToJson(ShipmentSummary instance) =>
    <String, dynamic>{
      'date_from': instance.dateFrom?.toIso8601String(),
      'date_to': instance.dateTo?.toIso8601String(),
      'total': instance.total,
      'by_status': instance.byStatus,
      'by_execution_status': instance.byExecutionStatus,
      'active_plans': instance.activePlans,
      'open_alerts': instance.openAlerts,
      'units_total': instance.unitsTotal,
      'generated_at': instance.generatedAt.toIso8601String(),
    };
