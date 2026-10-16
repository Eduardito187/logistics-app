// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'import_report_row.dart';

part 'import_report.g.dart';

@JsonSerializable()
class ImportReport {
  const ImportReport({
    required this.total,
    required this.imported,
    required this.duplicates,
    required this.failed,
    required this.rows,
  });

  factory ImportReport.fromJson(Map<String, Object?> json) =>
      _$ImportReportFromJson(json);

  final int total;
  final int imported;
  final int duplicates;
  final int failed;
  final List<ImportReportRow> rows;

  Map<String, Object?> toJson() => _$ImportReportToJson(this);
}
