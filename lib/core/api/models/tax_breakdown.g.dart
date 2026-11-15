// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaxBreakdown _$TaxBreakdownFromJson(Map<String, dynamic> json) => TaxBreakdown(
  ivaCents: (json['iva_cents'] as num?)?.toInt(),
  ivaBasisPoints: (json['iva_basis_points'] as num?)?.toInt(),
  itCents: (json['it_cents'] as num?)?.toInt(),
  itBasisPoints: (json['it_basis_points'] as num?)?.toInt(),
);

Map<String, dynamic> _$TaxBreakdownToJson(TaxBreakdown instance) =>
    <String, dynamic>{
      'iva_cents': instance.ivaCents,
      'iva_basis_points': instance.ivaBasisPoints,
      'it_cents': instance.itCents,
      'it_basis_points': instance.itBasisPoints,
    };
