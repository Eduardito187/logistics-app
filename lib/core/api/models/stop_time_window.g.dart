// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_time_window.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StopTimeWindow _$StopTimeWindowFromJson(Map<String, dynamic> json) =>
    StopTimeWindow(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
    );

Map<String, dynamic> _$StopTimeWindowToJson(StopTimeWindow instance) =>
    <String, dynamic>{
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
    };
