// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier.dart';
import 'list_meta.dart';

part 'get_app_carriers_response.g.dart';

@JsonSerializable()
class GetAppCarriersResponse {
  const GetAppCarriersResponse({required this.data, this.meta});

  factory GetAppCarriersResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppCarriersResponseFromJson(json);

  final List<Carrier> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() => _$GetAppCarriersResponseToJson(this);
}
