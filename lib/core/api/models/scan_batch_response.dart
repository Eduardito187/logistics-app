// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data.dart';
import 'meta10.dart';

part 'scan_batch_response.g.dart';

@JsonSerializable()
class ScanBatchResponse {
  const ScanBatchResponse({required this.data, required this.meta});

  factory ScanBatchResponse.fromJson(Map<String, Object?> json) =>
      _$ScanBatchResponseFromJson(json);

  final List<Data> data;
  final Meta10 meta;

  Map<String, Object?> toJson() => _$ScanBatchResponseToJson(this);
}
