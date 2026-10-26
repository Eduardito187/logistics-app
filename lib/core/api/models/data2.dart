// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_issue_type.dart';
import 'status2.dart';

part 'data2.g.dart';

@JsonSerializable()
class Data2 {
  const Data2({
    required this.shipmentId,
    required this.type,
    required this.status,
  });

  factory Data2.fromJson(Map<String, Object?> json) => _$Data2FromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final DeliveryIssueType type;
  final Status2 status;

  Map<String, Object?> toJson() => _$Data2ToJson(this);
}
