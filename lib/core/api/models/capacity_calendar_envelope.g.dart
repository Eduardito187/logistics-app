// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capacity_calendar_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CapacityCalendarEnvelope _$CapacityCalendarEnvelopeFromJson(
  Map<String, dynamic> json,
) => CapacityCalendarEnvelope(
  data: (json['data'] as List<dynamic>)
      .map((e) => CapacityBucket.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : Meta10.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CapacityCalendarEnvelopeToJson(
  CapacityCalendarEnvelope instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
