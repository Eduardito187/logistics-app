// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment_breadcrumbs.dart';

part 'get_app_telemetry_shipments_shipment_id_breadcrumbs_response.g.dart';

@JsonSerializable()
class GetAppTelemetryShipmentsShipmentIdBreadcrumbsResponse {
  const GetAppTelemetryShipmentsShipmentIdBreadcrumbsResponse({
    required this.data,
  });

  factory GetAppTelemetryShipmentsShipmentIdBreadcrumbsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTelemetryShipmentsShipmentIdBreadcrumbsResponseFromJson(json);

  final ShipmentBreadcrumbs data;

  Map<String, Object?> toJson() =>
      _$GetAppTelemetryShipmentsShipmentIdBreadcrumbsResponseToJson(this);
}
