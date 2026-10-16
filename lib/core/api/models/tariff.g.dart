// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tariff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tariff _$TariffFromJson(Map<String, dynamic> json) => Tariff(
  id: json['id'] as String,
  carrierId: json['carrier_id'] as String,
  corridorFrom: json['corridor_from'] as String,
  corridorTo: json['corridor_to'] as String,
  corridorType: CorridorType.fromJson(json['corridor_type'] as String),
  vehicleClass: VehicleClass.fromJson(json['vehicle_class'] as String),
  priceCents: (json['price_cents'] as num).toInt(),
  currency: json['currency'] as String,
  effectiveFrom: DateTime.parse(json['effective_from'] as String),
  carrierName: json['carrier_name'] as String?,
);

Map<String, dynamic> _$TariffToJson(Tariff instance) => <String, dynamic>{
  'id': instance.id,
  'carrier_id': instance.carrierId,
  'carrier_name': instance.carrierName,
  'corridor_from': instance.corridorFrom,
  'corridor_to': instance.corridorTo,
  'corridor_type': instance.corridorType,
  'vehicle_class': instance.vehicleClass,
  'price_cents': instance.priceCents,
  'currency': instance.currency,
  'effective_from': instance.effectiveFrom.toIso8601String(),
};
