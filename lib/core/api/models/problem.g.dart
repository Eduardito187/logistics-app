// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Problem _$ProblemFromJson(Map<String, dynamic> json) => Problem(
  title: json['title'] as String,
  status: (json['status'] as num).toInt(),
  code: ProblemCode.fromJson(json['code'] as String),
  type: json['type'] as String?,
  detail: json['detail'] as String?,
  instance: json['instance'] as String?,
  errors: (json['errors'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
  ),
);

Map<String, dynamic> _$ProblemToJson(Problem instance) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'status': instance.status,
  'detail': instance.detail,
  'instance': instance.instance,
  'code': instance.code,
  'errors': instance.errors,
};
