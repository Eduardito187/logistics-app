// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expense_category.dart';

part 'record_expense_request.g.dart';

@JsonSerializable()
class RecordExpenseRequest {
  const RecordExpenseRequest({
    required this.vehicleId,
    required this.category,
    required this.amountCents,
    required this.currency,
    required this.incurredAt,
    this.description,
    this.note,
  });

  factory RecordExpenseRequest.fromJson(Map<String, Object?> json) =>
      _$RecordExpenseRequestFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final ExpenseCategory category;
  @JsonKey(name: 'amount_cents')
  final int amountCents;
  final String currency;
  @JsonKey(name: 'incurred_at')
  final DateTime incurredAt;
  final String? description;
  final String? note;

  Map<String, Object?> toJson() => _$RecordExpenseRequestToJson(this);
}
