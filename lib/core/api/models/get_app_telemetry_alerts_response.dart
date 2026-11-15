// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'alert.dart';
import 'list_meta.dart';

part 'get_app_telemetry_alerts_response.g.dart';

@JsonSerializable()
class GetAppTelemetryAlertsResponse {
  const GetAppTelemetryAlertsResponse({required this.data, this.meta});

  factory GetAppTelemetryAlertsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppTelemetryAlertsResponseFromJson(json);

  final List<Alert> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() => _$GetAppTelemetryAlertsResponseToJson(this);
}
