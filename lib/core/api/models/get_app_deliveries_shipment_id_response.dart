// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery.dart';

part 'get_app_deliveries_shipment_id_response.g.dart';

@JsonSerializable()
class GetAppDeliveriesShipmentIdResponse {
  const GetAppDeliveriesShipmentIdResponse({required this.data});

  factory GetAppDeliveriesShipmentIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppDeliveriesShipmentIdResponseFromJson(json);

  final Delivery data;

  Map<String, Object?> toJson() =>
      _$GetAppDeliveriesShipmentIdResponseToJson(this);
}
