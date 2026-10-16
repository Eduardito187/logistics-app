// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'kind.dart';

part 'data.g.dart';

@JsonSerializable()
class Data {
  const Data({
    required this.kind,
    required this.disk,
    required this.path,
    required this.url,
  });

  factory Data.fromJson(Map<String, Object?> json) => _$DataFromJson(json);

  final Kind kind;

  /// Disco de evidencia donde quedó la foto
  final String disk;

  /// Referencia durable (relativa al disco); viaja como photo_path en la prueba de entrega
  final String path;

  /// URL de acceso si el disco la expone; null en discos privados
  final String? url;

  Map<String, Object?> toJson() => _$DataToJson(this);
}
