// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'windows.dart';

part 'app_delivery_calendar_open_request_body.g.dart';

@JsonSerializable()
class AppDeliveryCalendarOpenRequestBody {
  const AppDeliveryCalendarOpenRequestBody({
    required this.municipalityIds,
    required this.from,
    required this.to,
    required this.weekdays,
    required this.windows,
  });

  factory AppDeliveryCalendarOpenRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppDeliveryCalendarOpenRequestBodyFromJson(json);

  @JsonKey(name: 'municipality_ids')
  final List<String> municipalityIds;
  final DateTime from;
  final DateTime to;

  /// 1 = lunes … 7 = domingo
  final List<int> weekdays;
  final List<Windows> windows;

  Map<String, Object?> toJson() =>
      _$AppDeliveryCalendarOpenRequestBodyToJson(this);
}
