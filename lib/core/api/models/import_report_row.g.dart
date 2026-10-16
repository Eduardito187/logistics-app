// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_report_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportReportRow _$ImportReportRowFromJson(Map<String, dynamic> json) =>
    ImportReportRow(
      row: (json['row'] as num).toInt(),
      outcome: ImportRowOutcome.fromJson(json['outcome'] as String),
      externalId: json['external_id'] as String?,
      shipmentId: json['shipment_id'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ImportReportRowToJson(ImportReportRow instance) =>
    <String, dynamic>{
      'row': instance.row,
      'outcome': instance.outcome,
      'external_id': instance.externalId,
      'shipment_id': instance.shipmentId,
      'error': instance.error,
    };
