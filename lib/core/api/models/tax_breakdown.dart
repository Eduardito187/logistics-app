// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'tax_breakdown.g.dart';

@JsonSerializable()
class TaxBreakdown {
  const TaxBreakdown({
    this.ivaCents,
    this.ivaBasisPoints,
    this.itCents,
    this.itBasisPoints,
  });

  factory TaxBreakdown.fromJson(Map<String, Object?> json) =>
      _$TaxBreakdownFromJson(json);

  @JsonKey(name: 'iva_cents')
  final int? ivaCents;
  @JsonKey(name: 'iva_basis_points')
  final int? ivaBasisPoints;
  @JsonKey(name: 'it_cents')
  final int? itCents;
  @JsonKey(name: 'it_basis_points')
  final int? itBasisPoints;

  Map<String, Object?> toJson() => _$TaxBreakdownToJson(this);
}
