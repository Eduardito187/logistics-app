// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expense_category.dart';

part 'expense.g.dart';

/// A fleet expense charged to a vehicle
@JsonSerializable()
class Expense {
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.amountCents,
    required this.currency,
    required this.incurredAt,
    this.description,
    this.note,
  });

  factory Expense.fromJson(Map<String, Object?> json) =>
      _$ExpenseFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final ExpenseCategory category;
  @JsonKey(name: 'amount_cents')
  final int amountCents;
  final String currency;
  final String? description;
  @JsonKey(name: 'incurred_at')
  final DateTime incurredAt;
  final String? note;

  Map<String, Object?> toJson() => _$ExpenseToJson(this);
}
