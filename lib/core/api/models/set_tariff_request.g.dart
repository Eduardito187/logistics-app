// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_tariff_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetTariffRequest _$SetTariffRequestFromJson(Map<String, dynamic> json) =>
    SetTariffRequest(
      corridorFrom: json['corridor_from'] as String,
      corridorTo: json['corridor_to'] as String,
      corridorType: CorridorType.fromJson(json['corridor_type'] as String),
      vehicleClass: VehicleClass.fromJson(json['vehicle_class'] as String),
      priceCents: (json['price_cents'] as num).toInt(),
      currency: json['currency'] as String,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
    );

Map<String, dynamic> _$SetTariffRequestToJson(SetTariffRequest instance) =>
    <String, dynamic>{
      'corridor_from': instance.corridorFrom,
      'corridor_to': instance.corridorTo,
      'corridor_type': instance.corridorType,
      'vehicle_class': instance.vehicleClass,
      'price_cents': instance.priceCents,
      'currency': instance.currency,
      'effective_from': instance.effectiveFrom.toIso8601String(),
    };
