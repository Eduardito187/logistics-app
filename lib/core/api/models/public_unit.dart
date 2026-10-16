// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'unit_status.dart';

part 'public_unit.g.dart';

/// Vista pública de un bulto (sin PII)
@JsonSerializable()
class PublicUnit {
  const PublicUnit({
    required this.label,
    required this.status,
    required this.statusMessage,
  });

  factory PublicUnit.fromJson(Map<String, Object?> json) =>
      _$PublicUnitFromJson(json);

  /// Etiqueta humana del bulto, p. ej. "Bulto 1 de 2"
  final String label;
  final UnitStatus status;

  /// Mensaje por bulto en español, p. ej. "Cargado en el camión."
  @JsonKey(name: 'status_message')
  final String statusMessage;

  Map<String, Object?> toJson() => _$PublicUnitToJson(this);
}
