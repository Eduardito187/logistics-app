// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment.dart';

part 'post_app_shipments_shipment_geocode_response.g.dart';

@JsonSerializable()
class PostAppShipmentsShipmentGeocodeResponse {
  const PostAppShipmentsShipmentGeocodeResponse({required this.data});

  factory PostAppShipmentsShipmentGeocodeResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppShipmentsShipmentGeocodeResponseFromJson(json);

  final Shipment data;

  Map<String, Object?> toJson() =>
      _$PostAppShipmentsShipmentGeocodeResponseToJson(this);
}
