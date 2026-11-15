// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_city_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkCityCollection _$NetworkCityCollectionFromJson(
  Map<String, dynamic> json,
) => NetworkCityCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => NetworkCity.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NetworkCityCollectionToJson(
  NetworkCityCollection instance,
) => <String, dynamic>{'data': instance.data};
