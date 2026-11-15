// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_orders_order_number_vehicle_request_body.g.dart';

@JsonSerializable()
class AppOrdersOrderNumberVehicleRequestBody {
  const AppOrdersOrderNumberVehicleRequestBody({required this.vehicleId});

  factory AppOrdersOrderNumberVehicleRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppOrdersOrderNumberVehicleRequestBodyFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;

  Map<String, Object?> toJson() =>
      _$AppOrdersOrderNumberVehicleRequestBodyToJson(this);
}
