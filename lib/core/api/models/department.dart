// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// One of Bolivia's nine departments.
@JsonEnum()
enum Department {
  @JsonValue('la_paz')
  laPaz('la_paz'),
  @JsonValue('santa_cruz')
  santaCruz('santa_cruz'),
  @JsonValue('cochabamba')
  cochabamba('cochabamba'),
  @JsonValue('oruro')
  oruro('oruro'),
  @JsonValue('potosi')
  potosi('potosi'),
  @JsonValue('chuquisaca')
  chuquisaca('chuquisaca'),
  @JsonValue('tarija')
  tarija('tarija'),
  @JsonValue('beni')
  beni('beni'),
  @JsonValue('pando')
  pando('pando'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Department(this.json);

  factory Department.fromJson(String json) =>
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
  static List<Department> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
