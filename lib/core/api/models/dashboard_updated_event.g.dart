// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_updated_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardUpdatedEvent _$DashboardUpdatedEventFromJson(
  Map<String, dynamic> json,
) => DashboardUpdatedEvent(
  planDate: DateTime.parse(json['plan_date'] as String),
);

Map<String, dynamic> _$DashboardUpdatedEventToJson(
  DashboardUpdatedEvent instance,
) => <String, dynamic>{'plan_date': instance.planDate.toIso8601String()};
