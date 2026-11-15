// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Results _$ResultsFromJson(Map<String, dynamic> json) => Results(
  sku: json['sku'] as String,
  status: Status10.fromJson(json['status'] as String),
  message: json['message'] as String?,
);

Map<String, dynamic> _$ResultsToJson(Results instance) => <String, dynamic>{
  'sku': instance.sku,
  'status': instance.status,
  'message': instance.message,
};
