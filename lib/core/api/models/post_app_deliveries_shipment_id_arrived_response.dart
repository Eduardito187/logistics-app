// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'driver_route_stop.dart';

part 'post_app_deliveries_shipment_id_arrived_response.g.dart';

@JsonSerializable()
class PostAppDeliveriesShipmentIdArrivedResponse {
  const PostAppDeliveriesShipmentIdArrivedResponse({required this.data});

  factory PostAppDeliveriesShipmentIdArrivedResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveriesShipmentIdArrivedResponseFromJson(json);

  final DriverRouteStop data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveriesShipmentIdArrivedResponseToJson(this);
}
