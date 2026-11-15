// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'reschedule_shipments_result.dart';

part 'post_app_shipments_reschedule_response.g.dart';

@JsonSerializable()
class PostAppShipmentsRescheduleResponse {
  const PostAppShipmentsRescheduleResponse({required this.data});

  factory PostAppShipmentsRescheduleResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppShipmentsRescheduleResponseFromJson(json);

  final RescheduleShipmentsResult data;

  Map<String, Object?> toJson() =>
      _$PostAppShipmentsRescheduleResponseToJson(this);
}
