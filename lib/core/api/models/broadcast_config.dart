// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'broadcast_config.g.dart';

@JsonSerializable()
class BroadcastConfig {
  const BroadcastConfig({
    required this.enabled,
    required this.key,
    required this.cluster,
    required this.path,
    this.channels,
  });

  factory BroadcastConfig.fromJson(Map<String, Object?> json) =>
      _$BroadcastConfigFromJson(json);

  /// false = entorno sin tiempo real
  final bool enabled;

  /// Clave PÚBLICA de la app de sockets; null si enabled es false.
  final String? key;
  final String? cluster;

  /// Ruta base del WebSocket en el host de la API, p. ej. /app
  final String path;

  /// Tema → canales (con prefijo private-) que ESTE usuario puede escuchar. Temas: user (canal personal: inbox.updated, notifications.updated), fleet (fleet.position), planning (planning.run.updated, plans.updated). Tema ausente = sin tiempo real para esa pantalla. Son exactamente los canales que firma POST /app/broadcasting/auth para esa persona; la app no arma nombres.
  final Map<String, List<String>>? channels;

  Map<String, Object?> toJson() => _$BroadcastConfigToJson(this);
}
