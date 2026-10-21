// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data2.dart';

part 'post_app_deliveries_shipment_id_issues_response.g.dart';

@JsonSerializable()
class PostAppDeliveriesShipmentIdIssuesResponse {
  const PostAppDeliveriesShipmentIdIssuesResponse({required this.data});

  factory PostAppDeliveriesShipmentIdIssuesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveriesShipmentIdIssuesResponseFromJson(json);

  final Data2 data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveriesShipmentIdIssuesResponseToJson(this);
}
