// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_eta.dart';

part 'get_app_telemetry_shipments_shipment_id_eta_response.g.dart';

@JsonSerializable()
class GetAppTelemetryShipmentsShipmentIdEtaResponse {
  const GetAppTelemetryShipmentsShipmentIdEtaResponse({required this.data});

  factory GetAppTelemetryShipmentsShipmentIdEtaResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTelemetryShipmentsShipmentIdEtaResponseFromJson(json);

  final VehicleEta data;

  Map<String, Object?> toJson() =>
      _$GetAppTelemetryShipmentsShipmentIdEtaResponseToJson(this);
}
