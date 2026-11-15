// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_batch_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanBatchRequest _$ScanBatchRequestFromJson(Map<String, dynamic> json) =>
    ScanBatchRequest(
      items: (json['items'] as List<dynamic>)
          .map((e) => Items4.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ScanBatchRequestToJson(ScanBatchRequest instance) =>
    <String, dynamic>{'items': instance.items};
