// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sms_budget.g.dart';

/// Monthly SMS budget (P1-NOT-05).
@JsonSerializable()
class SmsBudget {
  const SmsBudget({
    required this.period,
    required this.sent,
    required this.cap,
    required this.remaining,
  });

  factory SmsBudget.fromJson(Map<String, Object?> json) =>
      _$SmsBudgetFromJson(json);

  final String period;
  final int sent;
  final int cap;
  final int remaining;

  Map<String, Object?> toJson() => _$SmsBudgetToJson(this);
}
