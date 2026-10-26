// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_order.dart';

part 'return_order_envelope.g.dart';

@JsonSerializable()
class ReturnOrderEnvelope {
  const ReturnOrderEnvelope({required this.data});

  factory ReturnOrderEnvelope.fromJson(Map<String, Object?> json) =>
      _$ReturnOrderEnvelopeFromJson(json);

  final ReturnOrder data;

  Map<String, Object?> toJson() => _$ReturnOrderEnvelopeToJson(this);
}
