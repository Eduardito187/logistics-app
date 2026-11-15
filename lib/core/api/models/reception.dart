// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status11.dart';

part 'reception.g.dart';

@JsonSerializable()
class Reception {
  const Reception({
    this.status,
    this.expectedCount,
    this.receivedCount,
    this.missingCount,
    this.surplusCount,
    this.openedAt,
    this.reconciledAt,
  });

  factory Reception.fromJson(Map<String, Object?> json) =>
      _$ReceptionFromJson(json);

  final Status11? status;
  @JsonKey(name: 'expected_count')
  final int? expectedCount;
  @JsonKey(name: 'received_count')
  final int? receivedCount;
  @JsonKey(name: 'missing_count')
  final int? missingCount;
  @JsonKey(name: 'surplus_count')
  final int? surplusCount;
  @JsonKey(name: 'opened_at')
  final DateTime? openedAt;
  @JsonKey(name: 'reconciled_at')
  final DateTime? reconciledAt;

  Map<String, Object?> toJson() => _$ReceptionToJson(this);
}
