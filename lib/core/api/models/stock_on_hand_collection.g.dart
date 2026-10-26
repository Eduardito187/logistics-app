// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_on_hand_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockOnHandCollection _$StockOnHandCollectionFromJson(
  Map<String, dynamic> json,
) => StockOnHandCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => StockOnHand.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StockOnHandCollectionToJson(
  StockOnHandCollection instance,
) => <String, dynamic>{'data': instance.data};
