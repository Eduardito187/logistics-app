// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'settlement.dart';

part 'get_app_carriers_settlements_settlement_id_response.g.dart';

@JsonSerializable()
class GetAppCarriersSettlementsSettlementIdResponse {
  const GetAppCarriersSettlementsSettlementIdResponse({required this.data});

  factory GetAppCarriersSettlementsSettlementIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppCarriersSettlementsSettlementIdResponseFromJson(json);

  final Settlement data;

  Map<String, Object?> toJson() =>
      _$GetAppCarriersSettlementsSettlementIdResponseToJson(this);
}
