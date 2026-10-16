// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'import_row_outcome.dart';

part 'import_report_row.g.dart';

@JsonSerializable()
class ImportReportRow {
  const ImportReportRow({
    required this.row,
    required this.outcome,
    required this.externalId,
    required this.shipmentId,
    required this.error,
  });

  factory ImportReportRow.fromJson(Map<String, Object?> json) =>
      _$ImportReportRowFromJson(json);

  /// 1-based row number in the uploaded file (1 is the header)
  final int row;
  final ImportRowOutcome outcome;
  @JsonKey(name: 'external_id')
  final String? externalId;
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  final String? error;

  Map<String, Object?> toJson() => _$ImportReportRowToJson(this);
}
