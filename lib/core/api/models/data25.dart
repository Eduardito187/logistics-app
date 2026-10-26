// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_type.dart';

part 'data25.g.dart';

@JsonSerializable()
class Data25 {
  const Data25({
    required this.shipmentId,
    required this.messageType,
    required this.status,
  });

  factory Data25.fromJson(Map<String, Object?> json) => _$Data25FromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final String status;

  Map<String, Object?> toJson() => _$Data25ToJson(this);
}
