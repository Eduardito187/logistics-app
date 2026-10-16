// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_problem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxProblem _$OutboxProblemFromJson(Map<String, dynamic> json) =>
    OutboxProblem(
      title: json['title'] as String,
      status: (json['status'] as num).toInt(),
      type: json['type'] as String?,
      detail: json['detail'] as String?,
    );

Map<String, dynamic> _$OutboxProblemToJson(OutboxProblem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'status': instance.status,
      'detail': instance.detail,
    };
