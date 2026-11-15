// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Results2 _$Results2FromJson(Map<String, dynamic> json) => Results2(
  index: (json['index'] as num).toInt(),
  status: Status12.fromJson(json['status'] as String),
  fixId: json['fix_id'] as String?,
  errors: (json['errors'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
  ),
);

Map<String, dynamic> _$Results2ToJson(Results2 instance) => <String, dynamic>{
  'index': instance.index,
  'fix_id': instance.fixId,
  'status': instance.status,
  'errors': instance.errors,
};
