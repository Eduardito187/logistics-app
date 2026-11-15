// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_city.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkCity _$NetworkCityFromJson(Map<String, dynamic> json) => NetworkCity(
  code: Department.fromJson(json['code'] as String),
  name: json['name'] as String,
  centralWarehouse: json['central_warehouse'] == null
      ? null
      : NetworkCityWarehouse.fromJson(
          json['central_warehouse'] as Map<String, dynamic>,
        ),
  nodesCount: (json['nodes_count'] as num).toInt(),
);

Map<String, dynamic> _$NetworkCityToJson(NetworkCity instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'central_warehouse': instance.centralWarehouse,
      'nodes_count': instance.nodesCount,
    };
