// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_delivery_issue_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportDeliveryIssueData _$ReportDeliveryIssueDataFromJson(
  Map<String, dynamic> json,
) => ReportDeliveryIssueData(
  shipmentId: json['shipment_id'] as String,
  type: DeliveryIssueType.fromJson(json['type'] as String),
  status: ReportDeliveryIssueDataStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$ReportDeliveryIssueDataToJson(
  ReportDeliveryIssueData instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'type': instance.type,
  'status': instance.status,
};
