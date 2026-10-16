// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum FailureReason {
  @JsonValue('CUSTOMER_ABSENT')
  customerAbsent('CUSTOMER_ABSENT'),
  @JsonValue('WRONG_ADDRESS')
  wrongAddress('WRONG_ADDRESS'),
  @JsonValue('REJECTED')
  rejected('REJECTED'),
  @JsonValue('DAMAGED')
  damaged('DAMAGED'),
  @JsonValue('OTHER')
  other('OTHER'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const FailureReason(this.json);

  factory FailureReason.fromJson(String json) =>
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
  static List<FailureReason> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
