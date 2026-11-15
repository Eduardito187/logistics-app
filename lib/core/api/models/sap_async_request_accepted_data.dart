// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sap_async_request_accepted_data_status.dart';

part 'sap_async_request_accepted_data.g.dart';

@JsonSerializable()
class SapAsyncRequestAcceptedData {
  const SapAsyncRequestAcceptedData({required this.status});

  factory SapAsyncRequestAcceptedData.fromJson(Map<String, Object?> json) =>
      _$SapAsyncRequestAcceptedDataFromJson(json);

  final SapAsyncRequestAcceptedDataStatus status;

  Map<String, Object?> toJson() => _$SapAsyncRequestAcceptedDataToJson(this);
}
