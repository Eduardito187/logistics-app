// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_transfer_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockTransferCollection _$StockTransferCollectionFromJson(
  Map<String, dynamic> json,
) => StockTransferCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => StockTransfer.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: Meta17.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StockTransferCollectionToJson(
  StockTransferCollection instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
