// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment.dart';

part 'get_app_shipments_shipment_response.g.dart';

@JsonSerializable()
class GetAppShipmentsShipmentResponse {
  const GetAppShipmentsShipmentResponse({required this.data});

  factory GetAppShipmentsShipmentResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppShipmentsShipmentResponseFromJson(json);

  final Shipment data;

  Map<String, Object?> toJson() =>
      _$GetAppShipmentsShipmentResponseToJson(this);
}
