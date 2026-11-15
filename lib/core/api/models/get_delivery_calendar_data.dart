// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'days.dart';

part 'get_delivery_calendar_data.g.dart';

@JsonSerializable()
class GetDeliveryCalendarData {
  const GetDeliveryCalendarData({
    this.from,
    this.to,
    this.municipalityId,
    this.days,
    this.blocked,
  });

  factory GetDeliveryCalendarData.fromJson(Map<String, Object?> json) =>
      _$GetDeliveryCalendarDataFromJson(json);

  final DateTime? from;
  final DateTime? to;
  @JsonKey(name: 'municipality_id')
  final String? municipalityId;
  final List<Days>? days;

  /// Bloqueos del rango (feriados, cierres)
  final List<dynamic>? blocked;

  Map<String, Object?> toJson() => _$GetDeliveryCalendarDataToJson(this);
}
