// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'network_city_warehouse.g.dart';

/// Almacén central de la ciudad: nodo activo de tipo distribution_center o central_warehouse; si hay varios, el primero por código
@JsonSerializable()
class NetworkCityWarehouse {
  const NetworkCityWarehouse({
    required this.nodeId,
    required this.code,
    required this.name,
  });

  factory NetworkCityWarehouse.fromJson(Map<String, Object?> json) =>
      _$NetworkCityWarehouseFromJson(json);

  @JsonKey(name: 'node_id')
  final String nodeId;
  final String code;
  final String name;

  Map<String, Object?> toJson() => _$NetworkCityWarehouseToJson(this);
}
