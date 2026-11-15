// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'stop_time_window.g.dart';

/// Delivery time chosen by the customer, anchored to the trip day (business time zone).
@JsonSerializable()
class StopTimeWindow {
  const StopTimeWindow({required this.from, required this.to});

  factory StopTimeWindow.fromJson(Map<String, Object?> json) =>
      _$StopTimeWindowFromJson(json);

  final DateTime from;
  final DateTime to;

  Map<String, Object?> toJson() => _$StopTimeWindowToJson(this);
}
