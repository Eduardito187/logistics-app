// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'corridor_type.dart';
import 'vehicle_class.dart';

part 'set_tariff_request.g.dart';

@JsonSerializable()
class SetTariffRequest {
  const SetTariffRequest({
    required this.corridorFrom,
    required this.corridorTo,
    required this.corridorType,
    required this.vehicleClass,
    required this.priceCents,
    required this.currency,
    required this.effectiveFrom,
  });

  factory SetTariffRequest.fromJson(Map<String, Object?> json) =>
      _$SetTariffRequestFromJson(json);

  @JsonKey(name: 'corridor_from')
  final String corridorFrom;
  @JsonKey(name: 'corridor_to')
  final String corridorTo;
  @JsonKey(name: 'corridor_type')
  final CorridorType corridorType;
  @JsonKey(name: 'vehicle_class')
  final VehicleClass vehicleClass;
  @JsonKey(name: 'price_cents')
  final int priceCents;
  final String currency;
  @JsonKey(name: 'effective_from')
  final DateTime effectiveFrom;

  Map<String, Object?> toJson() => _$SetTariffRequestToJson(this);
}
