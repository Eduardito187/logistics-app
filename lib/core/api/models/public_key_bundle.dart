// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'public_key.dart';

part 'public_key_bundle.g.dart';

@JsonSerializable()
class PublicKeyBundle {
  const PublicKeyBundle({
    required this.open,
    required this.activeKeyId,
    required this.keys,
  });

  factory PublicKeyBundle.fromJson(Map<String, Object?> json) =>
      _$PublicKeyBundleFromJson(json);

  /// Modo ABIERTO de etiquetas. Cuando es true, la app NO debe verificar la firma Ed25519 de NINGÚN QR (ni las k:0 nuevas ni las k:1 ya impresas) y valida por pertenencia (order_reference): así una etiqueta impresa nunca se rechaza por un problema de clave. Cuando es false, se verifica la firma de las etiquetas con k >= 1 contra las claves públicas de abajo.
  final bool open;

  /// Id de la clave activa, o null si no hay ninguna configurada
  @JsonKey(name: 'active_key_id')
  final int? activeKeyId;
  final List<PublicKey> keys;

  Map<String, Object?> toJson() => _$PublicKeyBundleToJson(this);
}
