// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'network_printer_language.dart';

part 'network_printer.g.dart';

/// Impresora de red registrada centralmente (admin → Configuración → Impresoras de red). La app la.
/// ofrece en "Impresoras de tu sede" y le imprime directo por TCP (host:port, RAW 9100 en Zebra).
///
@JsonSerializable()
class NetworkPrinter {
  const NetworkPrinter({
    required this.id,
    required this.name,
    required this.model,
    required this.host,
    required this.port,
    required this.language,
    required this.nodeId,
    required this.nodeName,
    required this.location,
  });

  factory NetworkPrinter.fromJson(Map<String, Object?> json) =>
      _$NetworkPrinterFromJson(json);

  final String id;
  final String name;
  final String? model;

  /// IP o hostname alcanzable desde la red de la sede, example: 192.168.2.50
  final String host;
  final int port;
  final NetworkPrinterLanguage language;

  /// Nodo de red (sede); null = compartida
  @JsonKey(name: 'node_id')
  final String? nodeId;

  /// Nombre legible de la sede
  @JsonKey(name: 'node_name')
  final String? nodeName;
  final String? location;

  Map<String, Object?> toJson() => _$NetworkPrinterToJson(this);
}
