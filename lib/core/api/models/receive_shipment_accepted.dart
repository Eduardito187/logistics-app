// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data26.dart';

part 'receive_shipment_accepted.g.dart';

@JsonSerializable()
class ReceiveShipmentAccepted {
  const ReceiveShipmentAccepted({required this.data});

  factory ReceiveShipmentAccepted.fromJson(Map<String, Object?> json) =>
      _$ReceiveShipmentAcceptedFromJson(json);

  final Data26 data;

  Map<String, Object?> toJson() => _$ReceiveShipmentAcceptedToJson(this);
}
