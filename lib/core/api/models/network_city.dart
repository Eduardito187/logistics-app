// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'department.dart';
import 'network_city_warehouse.dart';

part 'network_city.g.dart';

@JsonSerializable()
class NetworkCity {
  const NetworkCity({
    required this.code,
    required this.name,
    required this.centralWarehouse,
    required this.nodesCount,
  });

  factory NetworkCity.fromJson(Map<String, Object?> json) =>
      _$NetworkCityFromJson(json);

  final Department code;

  /// Nombre legible del departamento, p. ej. Potosí
  final String name;
  @JsonKey(name: 'central_warehouse')
  final NetworkCityWarehouse? centralWarehouse;

  /// Nodos activos de la red en ese departamento
  @JsonKey(name: 'nodes_count')
  final int nodesCount;

  Map<String, Object?> toJson() => _$NetworkCityToJson(this);
}
