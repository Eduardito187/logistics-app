// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum AlertType {
  @JsonValue('after_hours_movement')
  afterHoursMovement('after_hours_movement'),
  @JsonValue('excessive_idle')
  excessiveIdle('excessive_idle'),
  @JsonValue('geofence_violation')
  geofenceViolation('geofence_violation'),
  @JsonValue('unauthorized_use')
  unauthorizedUse('unauthorized_use'),
  @JsonValue('speeding')
  speeding('speeding'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const AlertType(this.json);

  factory AlertType.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;
  String toJson() {
    final value = json;
    if (value == null) {
      throw StateError(
        'Cannot convert enum value with null JSON representation to String. '
        'This usually happens for \$unknown or @JsonValue(null) entries.',
      );
    }
    return value as String;
  }

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<AlertType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
