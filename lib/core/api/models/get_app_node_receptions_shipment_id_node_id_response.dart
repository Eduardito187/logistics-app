// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'node_reception_view.dart';

part 'get_app_node_receptions_shipment_id_node_id_response.g.dart';

@JsonSerializable()
class GetAppNodeReceptionsShipmentIdNodeIdResponse {
  const GetAppNodeReceptionsShipmentIdNodeIdResponse({required this.data});

  factory GetAppNodeReceptionsShipmentIdNodeIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppNodeReceptionsShipmentIdNodeIdResponseFromJson(json);

  final NodeReceptionView data;

  Map<String, Object?> toJson() =>
      _$GetAppNodeReceptionsShipmentIdNodeIdResponseToJson(this);
}
