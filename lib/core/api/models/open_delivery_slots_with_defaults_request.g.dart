// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_delivery_slots_with_defaults_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenDeliverySlotsWithDefaultsRequest
_$OpenDeliverySlotsWithDefaultsRequestFromJson(
  Map<String, dynamic> json,
) => OpenDeliverySlotsWithDefaultsRequest(
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  from: json['from'] == null ? null : DateTime.parse(json['from'] as String),
  to: json['to'] == null ? null : DateTime.parse(json['to'] as String),
  municipalityIds: (json['municipality_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  weekdays: (json['weekdays'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$OpenDeliverySlotsWithDefaultsRequestToJson(
  OpenDeliverySlotsWithDefaultsRequest instance,
) => <String, dynamic>{
  'date': instance.date?.toIso8601String(),
  'from': instance.from?.toIso8601String(),
  'to': instance.to?.toIso8601String(),
  'municipality_ids': instance.municipalityIds,
  'weekdays': instance.weekdays,
};
