// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'plan_origin_node.g.dart';

/// Network node the truck departs from (its home base).
@JsonSerializable()
class PlanOriginNode {
  const PlanOriginNode({required this.id, required this.name});

  factory PlanOriginNode.fromJson(Map<String, Object?> json) =>
      _$PlanOriginNodeFromJson(json);

  final String id;
  final String name;

  Map<String, Object?> toJson() => _$PlanOriginNodeToJson(this);
}
