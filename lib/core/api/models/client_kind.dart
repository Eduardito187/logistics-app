// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Bucket de sesión explícito (opcional). Si se envía, gana sobre `platform`; si se omite, el backend lo deriva de `platform`. Útil para forzar el tipo de sesión desde un cliente.
@JsonEnum()
enum ClientKind {
  @JsonValue('web')
  web('web'),
  @JsonValue('app')
  app('app'),

  /// The name has been replaced because it contains a keyword. Original name: `null`.
  @JsonValue(null)
  valueNull(null),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ClientKind(this.json);

  factory ClientKind.fromJson(String? json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;
  String? toJson() {
    final value = json;
    if (value == null) {
      throw StateError(
        'Cannot convert enum value with null JSON representation to String?. '
        'This usually happens for \$unknown or @JsonValue(null) entries.',
      );
    }
    return value as String?;
  }

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<ClientKind> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
