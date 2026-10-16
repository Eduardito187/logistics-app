// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportReport _$ImportReportFromJson(Map<String, dynamic> json) => ImportReport(
  total: (json['total'] as num).toInt(),
  imported: (json['imported'] as num).toInt(),
  duplicates: (json['duplicates'] as num).toInt(),
  failed: (json['failed'] as num).toInt(),
  rows: (json['rows'] as List<dynamic>)
      .map((e) => ImportReportRow.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ImportReportToJson(ImportReport instance) =>
    <String, dynamic>{
      'total': instance.total,
      'imported': instance.imported,
      'duplicates': instance.duplicates,
      'failed': instance.failed,
      'rows': instance.rows,
    };
