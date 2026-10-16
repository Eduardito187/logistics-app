// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data.dart';

part 'post_app_deliveries_photos_response.g.dart';

@JsonSerializable()
class PostAppDeliveriesPhotosResponse {
  const PostAppDeliveriesPhotosResponse({required this.data});

  factory PostAppDeliveriesPhotosResponse.fromJson(Map<String, Object?> json) =>
      _$PostAppDeliveriesPhotosResponseFromJson(json);

  final Data data;

  Map<String, Object?> toJson() =>
      _$PostAppDeliveriesPhotosResponseToJson(this);
}
