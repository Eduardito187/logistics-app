// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data20.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data20 _$Data20FromJson(Map<String, dynamic> json) => Data20(
  eventId: json['event_id'] as String,
  status: Status5.fromJson(json['status'] as String),
);

Map<String, dynamic> _$Data20ToJson(Data20 instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'status': instance.status,
};
