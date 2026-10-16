// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_problem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingProblem _$SettingProblemFromJson(Map<String, dynamic> json) =>
    SettingProblem(
      title: json['title'] as String,
      status: (json['status'] as num).toInt(),
      type: json['type'] as String?,
      detail: json['detail'] as String?,
    );

Map<String, dynamic> _$SettingProblemToJson(SettingProblem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'status': instance.status,
      'detail': instance.detail,
    };
