// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_corridor.dart';
import 'list_meta.dart';

part 'get_app_carriers_corridors_response.g.dart';

@JsonSerializable()
class GetAppCarriersCorridorsResponse {
  const GetAppCarriersCorridorsResponse({required this.data, this.meta});

  factory GetAppCarriersCorridorsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppCarriersCorridorsResponseFromJson(json);

  final List<CarrierCorridor> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() =>
      _$GetAppCarriersCorridorsResponseToJson(this);
}
