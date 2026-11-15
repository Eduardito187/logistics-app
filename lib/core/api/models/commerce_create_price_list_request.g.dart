// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_create_price_list_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceCreatePriceListRequest _$CommerceCreatePriceListRequestFromJson(
  Map<String, dynamic> json,
) => CommerceCreatePriceListRequest(
  name: json['name'] as String,
  channel: SalesChannel.fromJson(json['channel'] as String),
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$CommerceCreatePriceListRequestToJson(
  CommerceCreatePriceListRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'channel': instance.channel,
  'currency': instance.currency,
};
