// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'public_key.g.dart';

@JsonSerializable()
class PublicKey {
  const PublicKey({required this.id, required this.publicKey});

  factory PublicKey.fromJson(Map<String, Object?> json) =>
      _$PublicKeyFromJson(json);

  /// Id de la clave (campo `k` del QR)
  final int id;

  /// Clave pública Ed25519 en base64
  @JsonKey(name: 'public_key')
  final String publicKey;

  Map<String, Object?> toJson() => _$PublicKeyToJson(this);
}
