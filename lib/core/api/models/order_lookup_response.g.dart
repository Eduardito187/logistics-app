// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_lookup_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderLookupResponse _$OrderLookupResponseFromJson(Map<String, dynamic> json) =>
    OrderLookupResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => OrderLookupItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: OrderLookupMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderLookupResponseToJson(
  OrderLookupResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
