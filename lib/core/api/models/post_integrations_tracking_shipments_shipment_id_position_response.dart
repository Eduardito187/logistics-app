// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data21.dart';

part 'post_integrations_tracking_shipments_shipment_id_position_response.g.dart';

@JsonSerializable()
class PostIntegrationsTrackingShipmentsShipmentIdPositionResponse {
  const PostIntegrationsTrackingShipmentsShipmentIdPositionResponse({
    required this.data,
  });

  factory PostIntegrationsTrackingShipmentsShipmentIdPositionResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsTrackingShipmentsShipmentIdPositionResponseFromJson(
    json,
  );

  final Data21 data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsTrackingShipmentsShipmentIdPositionResponseToJson(this);
}
