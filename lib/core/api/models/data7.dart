// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status2.dart';

part 'data7.g.dart';

@JsonSerializable()
class Data7 {
  const Data7({
    required this.eventId,
    required this.shipmentRef,
    required this.status,
  });

  factory Data7.fromJson(Map<String, Object?> json) => _$Data7FromJson(json);

  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'shipment_ref')
  final String shipmentRef;
  final Status2 status;

  Map<String, Object?> toJson() => _$Data7ToJson(this);
}
