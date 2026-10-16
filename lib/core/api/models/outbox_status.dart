// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Lifecycle status of an outbox message.
@JsonEnum()
enum OutboxStatus {
  @JsonValue('pending')
  pending('pending'),
  @JsonValue('failed')
  failed('failed'),
  @JsonValue('dispatched')
  dispatched('dispatched'),
  @JsonValue('dead_lettered')
  deadLettered('dead_lettered'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const OutboxStatus(this.json);

  factory OutboxStatus.fromJson(String json) =>
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
  static List<OutboxStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
