// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'department.dart';
import 'node_status.dart';
import 'node_type.dart';

part 'node.g.dart';

@JsonSerializable()
class Node {
  const Node({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.status,
    this.department,
  });

  factory Node.fromJson(Map<String, Object?> json) => _$NodeFromJson(json);

  final String id;
  final String code;
  final String name;
  final NodeType type;
  final double lat;
  final double lng;
  final NodeStatus status;

  /// Department the node sits in, or null when unassigned.
  final Department? department;

  Map<String, Object?> toJson() => _$NodeToJson(this);
}
