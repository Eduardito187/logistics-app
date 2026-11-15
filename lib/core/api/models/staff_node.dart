// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'staff_node.g.dart';

/// Tienda / nodo al que está asignada una persona
@JsonSerializable()
class StaffNode {
  const StaffNode({this.id, this.name, this.type, this.city});

  factory StaffNode.fromJson(Map<String, Object?> json) =>
      _$StaffNodeFromJson(json);

  final String? id;
  final String? name;
  final String? type;
  final String? city;

  Map<String, Object?> toJson() => _$StaffNodeToJson(this);
}
