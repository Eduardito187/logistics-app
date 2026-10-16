// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery.dart';

part 'post_app_deliveries_proof_of_delivery_response.g.dart';

@JsonSerializable()
class PostAppDeliveriesProofOfDeliveryResponse {
  const PostAppDeliveriesProofOfDeliveryResponse({required this.data});

  factory PostAppDeliveriesProofOfDeliveryResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveriesProofOfDeliveryResponseFromJson(json);

  final Delivery data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveriesProofOfDeliveryResponseToJson(this);
}
