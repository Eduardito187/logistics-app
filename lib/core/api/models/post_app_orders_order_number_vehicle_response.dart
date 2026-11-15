// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'assign_order_vehicle_data.dart';

part 'post_app_orders_order_number_vehicle_response.g.dart';

@JsonSerializable()
class PostAppOrdersOrderNumberVehicleResponse {
  const PostAppOrdersOrderNumberVehicleResponse({required this.data});

  factory PostAppOrdersOrderNumberVehicleResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppOrdersOrderNumberVehicleResponseFromJson(json);

  final AssignOrderVehicleData data;

  Map<String, Object?> toJson() =>
      _$PostAppOrdersOrderNumberVehicleResponseToJson(this);
}
