// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Delivery channel; the cascade walks them in cost order (all open-source transports).
@JsonEnum()
enum Channel {
  @JsonValue('PUSH_NTFY')
  pushNtfy('PUSH_NTFY'),
  @JsonValue('WEB_PUSH')
  webPush('WEB_PUSH'),
  @JsonValue('TELEGRAM')
  telegram('TELEGRAM'),
  @JsonValue('EMAIL')
  email('EMAIL'),
  @JsonValue('SMS')
  sms('SMS'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Channel(this.json);

  factory Channel.fromJson(String json) =>
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
  static List<Channel> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
