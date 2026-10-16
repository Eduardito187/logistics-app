// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settlement _$SettlementFromJson(Map<String, dynamic> json) => Settlement(
  id: json['id'] as String,
  carrierId: json['carrier_id'] as String,
  corridorFrom: json['corridor_from'] as String,
  corridorTo: json['corridor_to'] as String,
  corridorType: CorridorType.fromJson(json['corridor_type'] as String),
  period: json['period'] as String,
  amountCents: (json['amount_cents'] as num).toInt(),
  currency: json['currency'] as String,
  reference: json['reference'] as String,
  status: SettlementStatus.fromJson(json['status'] as String),
  documents: (json['documents'] as List<dynamic>)
      .map((e) => CarrierDocument.fromJson(e as Map<String, dynamic>))
      .toList(),
  carrierName: json['carrier_name'] as String?,
  disputeReason: json['dispute_reason'] as String?,
  paymentReference: json['payment_reference'] as String?,
);

Map<String, dynamic> _$SettlementToJson(Settlement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'carrier_id': instance.carrierId,
      'carrier_name': instance.carrierName,
      'corridor_from': instance.corridorFrom,
      'corridor_to': instance.corridorTo,
      'corridor_type': instance.corridorType,
      'period': instance.period,
      'amount_cents': instance.amountCents,
      'currency': instance.currency,
      'reference': instance.reference,
      'status': instance.status,
      'dispute_reason': instance.disputeReason,
      'payment_reference': instance.paymentReference,
      'documents': instance.documents,
    };
