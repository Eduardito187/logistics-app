// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Name not received and was auto-generated.
@JsonEnum()
enum Enum1 {
  @JsonValue('pod')
  pod('pod'),
  @JsonValue('damage')
  damage('damage'),
  @JsonValue('signature')
  signature('signature'),
  @JsonValue('id_document')
  idDocument('id_document'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Enum1(this.json);

  factory Enum1.fromJson(String json) =>
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
  static List<Enum1> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
