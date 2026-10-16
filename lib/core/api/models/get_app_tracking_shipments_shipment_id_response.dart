// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment_tracking.dart';

part 'get_app_tracking_shipments_shipment_id_response.g.dart';

@JsonSerializable()
class GetAppTrackingShipmentsShipmentIdResponse {
  const GetAppTrackingShipmentsShipmentIdResponse({required this.data});

  factory GetAppTrackingShipmentsShipmentIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTrackingShipmentsShipmentIdResponseFromJson(json);

  final ShipmentTracking data;

  Map<String, Object?> toJson() =>
      _$GetAppTrackingShipmentsShipmentIdResponseToJson(this);
}
