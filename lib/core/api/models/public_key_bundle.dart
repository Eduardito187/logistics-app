// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'public_key.dart';

part 'public_key_bundle.g.dart';

@JsonSerializable()
class PublicKeyBundle {
  const PublicKeyBundle({required this.activeKeyId, required this.keys});

  factory PublicKeyBundle.fromJson(Map<String, Object?> json) =>
      _$PublicKeyBundleFromJson(json);

  /// Id de la clave activa, o null si no hay ninguna configurada
  @JsonKey(name: 'active_key_id')
  final int? activeKeyId;
  final List<PublicKey> keys;

  Map<String, Object?> toJson() => _$PublicKeyBundleToJson(this);
}
