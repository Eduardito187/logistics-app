// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Shipment fact that triggers a notification.
@JsonEnum()
enum MessageType {
  @JsonValue('EN_ROUTE')
  enRoute('EN_ROUTE'),
  @JsonValue('ARRIVING')
  arriving('ARRIVING'),
  @JsonValue('DELIVERED')
  delivered('DELIVERED'),
  @JsonValue('FAILED')
  failed('FAILED'),
  @JsonValue('CONFIRM_LOCATION')
  confirmLocation('CONFIRM_LOCATION'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const MessageType(this.json);

  factory MessageType.fromJson(String json) =>
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
  static List<MessageType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
