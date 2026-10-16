// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmsBudget _$SmsBudgetFromJson(Map<String, dynamic> json) => SmsBudget(
  period: json['period'] as String,
  sent: (json['sent'] as num).toInt(),
  cap: (json['cap'] as num).toInt(),
  remaining: (json['remaining'] as num).toInt(),
);

Map<String, dynamic> _$SmsBudgetToJson(SmsBudget instance) => <String, dynamic>{
  'period': instance.period,
  'sent': instance.sent,
  'cap': instance.cap,
  'remaining': instance.remaining,
};
