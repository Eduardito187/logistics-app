// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'origin.g.dart';

@JsonSerializable()
class Origin {
  const Origin({required this.code, required this.name});

  factory Origin.fromJson(Map<String, Object?> json) => _$OriginFromJson(json);

  /// Código de origen del QR (free-form; suele ser un code de nodo)
  final String code;

  /// Nombre humano del nodo de origen si `code` matchea network; si no, null (mostrar name ?? code)
  final String? name;

  Map<String, Object?> toJson() => _$OriginToJson(this);
}
