// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data9.dart';

part 'get_app_tracking_shipments_shipment_id_units_response.g.dart';

@JsonSerializable()
class GetAppTrackingShipmentsShipmentIdUnitsResponse {
  const GetAppTrackingShipmentsShipmentIdUnitsResponse({required this.data});

  factory GetAppTrackingShipmentsShipmentIdUnitsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTrackingShipmentsShipmentIdUnitsResponseFromJson(json);

  final Data9 data;

  Map<String, Object?> toJson() =>
      _$GetAppTrackingShipmentsShipmentIdUnitsResponseToJson(this);
}
