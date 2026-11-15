// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_issue_type.dart';
import 'report_delivery_issue_data_status.dart';

part 'report_delivery_issue_data.g.dart';

@JsonSerializable()
class ReportDeliveryIssueData {
  const ReportDeliveryIssueData({
    required this.shipmentId,
    required this.type,
    required this.status,
  });

  factory ReportDeliveryIssueData.fromJson(Map<String, Object?> json) =>
      _$ReportDeliveryIssueDataFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final DeliveryIssueType type;
  final ReportDeliveryIssueDataStatus status;

  Map<String, Object?> toJson() => _$ReportDeliveryIssueDataToJson(this);
}
