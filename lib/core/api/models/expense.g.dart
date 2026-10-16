// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  category: ExpenseCategory.fromJson(json['category'] as String),
  amountCents: (json['amount_cents'] as num).toInt(),
  currency: json['currency'] as String,
  incurredAt: DateTime.parse(json['incurred_at'] as String),
  description: json['description'] as String?,
  note: json['note'] as String?,
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'category': instance.category,
  'amount_cents': instance.amountCents,
  'currency': instance.currency,
  'description': instance.description,
  'incurred_at': instance.incurredAt.toIso8601String(),
  'note': instance.note,
};
