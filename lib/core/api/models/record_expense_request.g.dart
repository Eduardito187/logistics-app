// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_expense_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordExpenseRequest _$RecordExpenseRequestFromJson(
  Map<String, dynamic> json,
) => RecordExpenseRequest(
  vehicleId: json['vehicle_id'] as String,
  category: ExpenseCategory.fromJson(json['category'] as String),
  amountCents: (json['amount_cents'] as num).toInt(),
  currency: json['currency'] as String,
  incurredAt: DateTime.parse(json['incurred_at'] as String),
  description: json['description'] as String?,
  note: json['note'] as String?,
);

Map<String, dynamic> _$RecordExpenseRequestToJson(
  RecordExpenseRequest instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'category': instance.category,
  'amount_cents': instance.amountCents,
  'currency': instance.currency,
  'incurred_at': instance.incurredAt.toIso8601String(),
  'description': instance.description,
  'note': instance.note,
};
