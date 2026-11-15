// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_batch_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanBatchResponse _$ScanBatchResponseFromJson(Map<String, dynamic> json) =>
    ScanBatchResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => Data.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: Meta10.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ScanBatchResponseToJson(ScanBatchResponse instance) =>
    <String, dynamic>{'data': instance.data, 'meta': instance.meta};
