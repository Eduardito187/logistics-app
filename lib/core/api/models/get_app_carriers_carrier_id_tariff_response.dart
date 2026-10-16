// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'tariff.dart';

part 'get_app_carriers_carrier_id_tariff_response.g.dart';

@JsonSerializable()
class GetAppCarriersCarrierIdTariffResponse {
  const GetAppCarriersCarrierIdTariffResponse({required this.data});

  factory GetAppCarriersCarrierIdTariffResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppCarriersCarrierIdTariffResponseFromJson(json);

  final Tariff data;

  Map<String, Object?> toJson() =>
      _$GetAppCarriersCarrierIdTariffResponseToJson(this);
}
