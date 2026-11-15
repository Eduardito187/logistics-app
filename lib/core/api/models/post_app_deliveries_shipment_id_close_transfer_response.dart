// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery.dart';

part 'post_app_deliveries_shipment_id_close_transfer_response.g.dart';

@JsonSerializable()
class PostAppDeliveriesShipmentIdCloseTransferResponse {
  const PostAppDeliveriesShipmentIdCloseTransferResponse({required this.data});

  factory PostAppDeliveriesShipmentIdCloseTransferResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveriesShipmentIdCloseTransferResponseFromJson(json);

  final Delivery data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveriesShipmentIdCloseTransferResponseToJson(this);
}
