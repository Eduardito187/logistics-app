// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'receiving_dock_day.dart';

part 'receiving_calendar_collection.g.dart';

@JsonSerializable()
class ReceivingCalendarCollection {
  const ReceivingCalendarCollection({required this.data});

  factory ReceivingCalendarCollection.fromJson(Map<String, Object?> json) =>
      _$ReceivingCalendarCollectionFromJson(json);

  final List<ReceivingDockDay> data;

  Map<String, Object?> toJson() => _$ReceivingCalendarCollectionToJson(this);
}
