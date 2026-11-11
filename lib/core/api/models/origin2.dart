// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'origin2.g.dart';

@JsonSerializable()
class Origin2 {
  const Origin2({required this.code, required this.name});

  factory Origin2.fromJson(Map<String, Object?> json) =>
      _$Origin2FromJson(json);

  final String code;

  /// Nombre de nodo si `code` matchea network; si no, null (mostrar name ?? code). Vacío en líneas pending.
  final String? name;

  Map<String, Object?> toJson() => _$Origin2ToJson(this);
}
