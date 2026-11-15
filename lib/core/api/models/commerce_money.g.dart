// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_money.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceMoney _$CommerceMoneyFromJson(Map<String, dynamic> json) =>
    CommerceMoney(
      cents: (json['cents'] as num).toInt(),
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$CommerceMoneyToJson(CommerceMoney instance) =>
    <String, dynamic>{'cents': instance.cents, 'currency': instance.currency};
