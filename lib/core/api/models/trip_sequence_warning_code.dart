// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum TripSequenceWarningCode {
  @JsonValue('window_missed')
  windowMissed('window_missed'),
  @JsonValue('over_capacity')
  overCapacity('over_capacity'),
  @JsonValue('out_of_department')
  outOfDepartment('out_of_department'),
  @JsonValue('missing_location')
  missingLocation('missing_location'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const TripSequenceWarningCode(this.json);

  factory TripSequenceWarningCode.fromJson(String json) =>
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
  static List<TripSequenceWarningCode> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
