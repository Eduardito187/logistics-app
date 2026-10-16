// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery.dart';

part 'post_app_deliveries_scans_unload_response.g.dart';

@JsonSerializable()
class PostAppDeliveriesScansUnloadResponse {
  const PostAppDeliveriesScansUnloadResponse({required this.data});

  factory PostAppDeliveriesScansUnloadResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppDeliveriesScansUnloadResponseFromJson(json);

  final Delivery data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveriesScansUnloadResponseToJson(this);
}
