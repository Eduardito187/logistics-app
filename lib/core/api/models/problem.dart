// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'problem_code.dart';

part 'problem.g.dart';

/// RFC 7807 problem+json. Forma uniforme de error de las tres puertas de la API. Los.
/// clientes deben ramificar por `code` (legible por máquina y estable), no por `title`.
///
@JsonSerializable()
class Problem {
  const Problem({
    required this.title,
    required this.status,
    required this.code,
    this.type,
    this.detail,
    this.instance,
    this.errors,
  });

  factory Problem.fromJson(Map<String, Object?> json) =>
      _$ProblemFromJson(json);

  /// URI de referencia del tipo de problema; "<base>/<code>".
  final String? type;

  /// Resumen corto y estable legible por humanos.
  final String title;

  /// Mismo valor que el estado HTTP de la respuesta.
  final int status;

  /// Explicación específica de esta ocurrencia.
  final String? detail;

  /// Ruta de la petición que produjo el error.
  final String? instance;
  final ProblemCode code;

  /// Errores por campo; presente solo en fallos de validación (code=validation_failed).
  final Map<String, List<String>>? errors;

  Map<String, Object?> toJson() => _$ProblemToJson(this);
}
