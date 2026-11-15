// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'client_kind.dart';

part 'device.g.dart';

@JsonSerializable()
class Device {
  const Device({
    required this.fingerprint,
    this.platform,
    this.clientKind,
    this.name,
    this.pushToken,
  });

  factory Device.fromJson(Map<String, Object?> json) => _$DeviceFromJson(json);

  final String fingerprint;

  /// Plataforma del equipo (android|ios|web|desktop). Determina el BUCKET de sesión: android/ios (y cualquier valor no-web) = `app`; web/desktop/browser = `web`. Máx 1 sesión activa por bucket por usuario (ver client_kind y el error session_superseded).
  final String? platform;

  /// Bucket de sesión explícito (opcional). Si se envía, gana sobre `platform`; si se omite, el backend lo deriva de `platform`. Útil para forzar el tipo de sesión desde un cliente.
  @JsonKey(name: 'client_kind')
  final ClientKind? clientKind;
  final String? name;
  @JsonKey(name: 'push_token')
  final String? pushToken;

  Map<String, Object?> toJson() => _$DeviceToJson(this);
}
