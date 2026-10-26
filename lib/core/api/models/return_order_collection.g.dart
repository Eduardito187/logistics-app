// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_order_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReturnOrderCollection _$ReturnOrderCollectionFromJson(
  Map<String, dynamic> json,
) => ReturnOrderCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => ReturnOrder.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReturnOrderCollectionToJson(
  ReturnOrderCollection instance,
) => <String, dynamic>{'data': instance.data};
