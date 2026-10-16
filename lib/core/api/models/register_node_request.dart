// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'department.dart';
import 'node_type.dart';

part 'register_node_request.g.dart';

@JsonSerializable()
class RegisterNodeRequest {
  const RegisterNodeRequest({
    required this.code,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.department,
  });

  factory RegisterNodeRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterNodeRequestFromJson(json);

  final String code;
  final String name;
  final NodeType type;
  final double latitude;
  final double longitude;

  /// Department the node sits in. Optional; may be assigned later.
  final Department? department;

  Map<String, Object?> toJson() => _$RegisterNodeRequestToJson(this);
}
