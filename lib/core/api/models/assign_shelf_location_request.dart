// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'assign_shelf_location_request.g.dart';

@JsonSerializable()
class AssignShelfLocationRequest {
  const AssignShelfLocationRequest({
    required this.nodeId,
    required this.location,
    required this.occurredAt,
    this.unitIds,
  });

  factory AssignShelfLocationRequest.fromJson(Map<String, Object?> json) =>
      _$AssignShelfLocationRequestFromJson(json);

  @JsonKey(name: 'node_id')
  final String nodeId;
  final String location;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  /// Required on the batch route.
  @JsonKey(name: 'unit_ids')
  final List<String>? unitIds;

  Map<String, Object?> toJson() => _$AssignShelfLocationRequestToJson(this);
}
