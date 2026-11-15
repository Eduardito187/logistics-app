// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'network_city.dart';

part 'network_city_collection.g.dart';

@JsonSerializable()
class NetworkCityCollection {
  const NetworkCityCollection({required this.data});

  factory NetworkCityCollection.fromJson(Map<String, Object?> json) =>
      _$NetworkCityCollectionFromJson(json);

  final List<NetworkCity> data;

  Map<String, Object?> toJson() => _$NetworkCityCollectionToJson(this);
}
