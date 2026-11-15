// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error8.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Error8 _$Error8FromJson(Map<String, dynamic> json) => Error8(
  code: ProblemCode.fromJson(json['code'] as String),
  message: json['message'] as String,
);

Map<String, dynamic> _$Error8ToJson(Error8 instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
};
