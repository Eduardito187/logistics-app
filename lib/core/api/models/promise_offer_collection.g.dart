// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promise_offer_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromiseOfferCollection _$PromiseOfferCollectionFromJson(
  Map<String, dynamic> json,
) => PromiseOfferCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => PromiseOffer.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: Meta9.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PromiseOfferCollectionToJson(
  PromiseOfferCollection instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
