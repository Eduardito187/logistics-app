// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_calendar_unit_option_value.dart';

part 'delivery_calendar_unit_option.g.dart';

@JsonSerializable()
class DeliveryCalendarUnitOption {
  const DeliveryCalendarUnitOption({required this.value, required this.label});

  factory DeliveryCalendarUnitOption.fromJson(Map<String, Object?> json) =>
      _$DeliveryCalendarUnitOptionFromJson(json);

  final DeliveryCalendarUnitOptionValue value;
  final String label;

  Map<String, Object?> toJson() => _$DeliveryCalendarUnitOptionToJson(this);
}
