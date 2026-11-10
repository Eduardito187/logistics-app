// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'type3.dart';

part 'destination.g.dart';

@JsonSerializable()
class Destination {
  const Destination({
    required this.type,
    required this.name,
    required this.address,
  });

  factory Destination.fromJson(Map<String, Object?> json) =>
      _$DestinationFromJson(json);

  /// home = domicilio del cliente; store = tienda/punto de retiro; warehouse = centro de distribución/almacén. null si no se pudo determinar el envío.
  final Type3? type;

  /// Nombre del destino (cliente en home; nombre del nodo en store/warehouse)
  final String? name;

  /// Dirección (solo en home; null en nodo)
  final String? address;

  Map<String, Object?> toJson() => _$DestinationToJson(this);
}
