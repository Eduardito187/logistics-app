// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery.dart';

part 'post_app_deliveries_scans_preparation_response.g.dart';

@JsonSerializable()
class PostAppDeliveriesScansPreparationResponse {
  const PostAppDeliveriesScansPreparationResponse({required this.data});

  factory PostAppDeliveriesScansPreparationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveriesScansPreparationResponseFromJson(json);

  final Delivery data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveriesScansPreparationResponseToJson(this);
}
