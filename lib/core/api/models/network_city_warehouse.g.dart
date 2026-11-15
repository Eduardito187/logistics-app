// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_city_warehouse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkCityWarehouse _$NetworkCityWarehouseFromJson(
  Map<String, dynamic> json,
) => NetworkCityWarehouse(
  nodeId: json['node_id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$NetworkCityWarehouseToJson(
  NetworkCityWarehouse instance,
) => <String, dynamic>{
  'node_id': instance.nodeId,
  'code': instance.code,
  'name': instance.name,
};
