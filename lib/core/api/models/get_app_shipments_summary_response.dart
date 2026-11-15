// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment_summary.dart';

part 'get_app_shipments_summary_response.g.dart';

@JsonSerializable()
class GetAppShipmentsSummaryResponse {
  const GetAppShipmentsSummaryResponse({required this.data});

  factory GetAppShipmentsSummaryResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppShipmentsSummaryResponseFromJson(json);

  final ShipmentSummary data;

  Map<String, Object?> toJson() => _$GetAppShipmentsSummaryResponseToJson(this);
}
