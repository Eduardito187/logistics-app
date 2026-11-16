// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plans_updated_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlansUpdatedEvent _$PlansUpdatedEventFromJson(Map<String, dynamic> json) =>
    PlansUpdatedEvent(
      planDate: DateTime.parse(json['plan_date'] as String),
      deleted: json['deleted'] as bool,
      planId: json['plan_id'] as String?,
    );

Map<String, dynamic> _$PlansUpdatedEventToJson(PlansUpdatedEvent instance) =>
    <String, dynamic>{
      'plan_date': instance.planDate.toIso8601String(),
      'deleted': instance.deleted,
      'plan_id': instance.planId,
    };
