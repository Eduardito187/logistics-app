// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementLine _$SettlementLineFromJson(Map<String, dynamic> json) =>
    SettlementLine(
      shipmentId: json['shipment_id'] as String,
      dispatchReference: json['dispatch_reference'] as String,
      baseAmountCents: (json['base_amount_cents'] as num).toInt(),
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$SettlementLineToJson(SettlementLine instance) =>
    <String, dynamic>{
      'shipment_id': instance.shipmentId,
      'dispatch_reference': instance.dispatchReference,
      'base_amount_cents': instance.baseAmountCents,
      'currency': instance.currency,
    };
