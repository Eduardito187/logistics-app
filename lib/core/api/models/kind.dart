// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum Kind {
  @JsonValue('preparation')
  preparation('preparation'),
  @JsonValue('load')
  load('load'),
  @JsonValue('unload')
  unload('unload'),
  @JsonValue('departure')
  departure('departure'),
  @JsonValue('arrival')
  arrival('arrival'),
  @JsonValue('proof_of_delivery')
  proofOfDelivery('proof_of_delivery'),
  @JsonValue('failed')
  failed('failed'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Kind(this.json);

  factory Kind.fromJson(String json) =>
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
  static List<Kind> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
