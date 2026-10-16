// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_settlement_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmitSettlementRequest _$SubmitSettlementRequestFromJson(
  Map<String, dynamic> json,
) => SubmitSettlementRequest(
  corridorFrom: json['corridor_from'] as String,
  corridorTo: json['corridor_to'] as String,
  corridorType: CorridorType.fromJson(json['corridor_type'] as String),
  period: json['period'] as String,
  amountCents: (json['amount_cents'] as num).toInt(),
  currency: json['currency'] as String,
  reference: json['reference'] as String,
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => CarrierDocument.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SubmitSettlementRequestToJson(
  SubmitSettlementRequest instance,
) => <String, dynamic>{
  'corridor_from': instance.corridorFrom,
  'corridor_to': instance.corridorTo,
  'corridor_type': instance.corridorType,
  'period': instance.period,
  'amount_cents': instance.amountCents,
  'currency': instance.currency,
  'reference': instance.reference,
  'documents': instance.documents,
};
