// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_price_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommercePriceList _$CommercePriceListFromJson(Map<String, dynamic> json) =>
    CommercePriceList(
      id: json['id'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String,
      channel: SalesChannel.fromJson(json['channel'] as String),
      status: CommercePriceListStatus.fromJson(json['status'] as String),
    );

Map<String, dynamic> _$CommercePriceListToJson(CommercePriceList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'currency': instance.currency,
      'channel': instance.channel,
      'status': instance.status,
    };
