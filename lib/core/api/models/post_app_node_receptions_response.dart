// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'node_reception_view.dart';

part 'post_app_node_receptions_response.g.dart';

@JsonSerializable()
class PostAppNodeReceptionsResponse {
  const PostAppNodeReceptionsResponse({required this.data});

  factory PostAppNodeReceptionsResponse.fromJson(Map<String, Object?> json) =>
      _$PostAppNodeReceptionsResponseFromJson(json);

  final NodeReceptionView data;

  Map<String, Object?> toJson() => _$PostAppNodeReceptionsResponseToJson(this);
}
