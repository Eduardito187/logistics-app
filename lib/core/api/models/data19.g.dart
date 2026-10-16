// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data19.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data19 _$Data19FromJson(Map<String, dynamic> json) => Data19(
  eventId: json['event_id'] as String,
  status: Status4.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data19ToJson(Data19 instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'status': instance.status,
};
