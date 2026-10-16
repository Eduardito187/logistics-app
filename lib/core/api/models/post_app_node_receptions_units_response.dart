// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'node_reception_view.dart';

part 'post_app_node_receptions_units_response.g.dart';

@JsonSerializable()
class PostAppNodeReceptionsUnitsResponse {
  const PostAppNodeReceptionsUnitsResponse({required this.data});

  factory PostAppNodeReceptionsUnitsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppNodeReceptionsUnitsResponseFromJson(json);

  final NodeReceptionView data;

  Map<String, Object?> toJson() =>
      _$PostAppNodeReceptionsUnitsResponseToJson(this);
}
