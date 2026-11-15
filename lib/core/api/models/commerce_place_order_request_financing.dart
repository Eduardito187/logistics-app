// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Forma de financiamiento. Determina qué habilita el paso a procesando: contado = pago capturado; crédito sin inicial = firma de contrato; crédito con inicial = firma de contrato + pago del inicial.
@JsonEnum()
enum CommercePlaceOrderRequestFinancing {
  @JsonValue('cash')
  cash('cash'),
  @JsonValue('credit_with_initial')
  creditWithInitial('credit_with_initial'),
  @JsonValue('credit_without_initial')
  creditWithoutInitial('credit_without_initial'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const CommercePlaceOrderRequestFinancing(this.json);

  factory CommercePlaceOrderRequestFinancing.fromJson(String json) =>
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
  static List<CommercePlaceOrderRequestFinancing> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
