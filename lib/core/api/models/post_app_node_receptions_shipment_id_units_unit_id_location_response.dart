// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'node_reception_view.dart';

part 'post_app_node_receptions_shipment_id_units_unit_id_location_response.g.dart';

@JsonSerializable()
class PostAppNodeReceptionsShipmentIdUnitsUnitIdLocationResponse {
  const PostAppNodeReceptionsShipmentIdUnitsUnitIdLocationResponse({
    required this.data,
  });

  factory PostAppNodeReceptionsShipmentIdUnitsUnitIdLocationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppNodeReceptionsShipmentIdUnitsUnitIdLocationResponseFromJson(
    json,
  );

  final NodeReceptionView data;

  Map<String, Object?> toJson() =>
      _$PostAppNodeReceptionsShipmentIdUnitsUnitIdLocationResponseToJson(this);
}
