// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_fee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FixedFee _$FixedFeeFromJson(Map<String, dynamic> json) => FixedFee(
  cents: (json['cents'] as num).toInt(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$FixedFeeToJson(FixedFee instance) => <String, dynamic>{
  'cents': instance.cents,
  'currency': instance.currency,
};
