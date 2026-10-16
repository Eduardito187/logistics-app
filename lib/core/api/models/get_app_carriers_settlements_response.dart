// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'settlement.dart';

part 'get_app_carriers_settlements_response.g.dart';

@JsonSerializable()
class GetAppCarriersSettlementsResponse {
  const GetAppCarriersSettlementsResponse({required this.data});

  factory GetAppCarriersSettlementsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppCarriersSettlementsResponseFromJson(json);

  final List<Settlement> data;

  Map<String, Object?> toJson() =>
      _$GetAppCarriersSettlementsResponseToJson(this);
}
