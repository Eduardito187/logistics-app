// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'type4.dart';

part 'destination2.g.dart';

@JsonSerializable()
class Destination2 {
  const Destination2({
    required this.type,
    required this.name,
    required this.address,
  });

  factory Destination2.fromJson(Map<String, Object?> json) =>
      _$Destination2FromJson(json);

  /// home = domicilio del cliente; store = tienda/punto de retiro; warehouse = centro de distribución/almacén. null si no se pudo determinar el envío.
  final Type4? type;

  /// Nombre del destino (cliente en home; nombre del nodo en store/warehouse)
  final String? name;

  /// Dirección (solo en home; null en nodo)
  final String? address;

  Map<String, Object?> toJson() => _$Destination2ToJson(this);
}
