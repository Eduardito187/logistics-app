// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'items4.dart';

part 'scan_batch_request.g.dart';

@JsonSerializable()
class ScanBatchRequest {
  const ScanBatchRequest({required this.items});

  factory ScanBatchRequest.fromJson(Map<String, Object?> json) =>
      _$ScanBatchRequestFromJson(json);

  final List<Items4> items;

  Map<String, Object?> toJson() => _$ScanBatchRequestToJson(this);
}
