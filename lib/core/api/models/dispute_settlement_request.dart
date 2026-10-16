// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dispute_settlement_request.g.dart';

@JsonSerializable()
class DisputeSettlementRequest {
  const DisputeSettlementRequest({required this.reason});

  factory DisputeSettlementRequest.fromJson(Map<String, Object?> json) =>
      _$DisputeSettlementRequestFromJson(json);

  final String reason;

  Map<String, Object?> toJson() => _$DisputeSettlementRequestToJson(this);
}
