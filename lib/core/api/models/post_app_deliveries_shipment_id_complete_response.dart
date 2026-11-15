// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery.dart';

part 'post_app_deliveries_shipment_id_complete_response.g.dart';

@JsonSerializable()
class PostAppDeliveriesShipmentIdCompleteResponse {
  const PostAppDeliveriesShipmentIdCompleteResponse({required this.data});

  factory PostAppDeliveriesShipmentIdCompleteResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveriesShipmentIdCompleteResponseFromJson(json);

  final Delivery data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveriesShipmentIdCompleteResponseToJson(this);
}
