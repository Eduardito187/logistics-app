// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_history_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingHistoryEnvelope _$SettingHistoryEnvelopeFromJson(
  Map<String, dynamic> json,
) => SettingHistoryEnvelope(
  data: (json['data'] as List<dynamic>)
      .map((e) => SettingVersion.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : Meta16.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SettingHistoryEnvelopeToJson(
  SettingHistoryEnvelope instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
