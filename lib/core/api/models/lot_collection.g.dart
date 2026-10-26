// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LotCollection _$LotCollectionFromJson(Map<String, dynamic> json) =>
    LotCollection(
      data: (json['data'] as List<dynamic>)
          .map((e) => Lot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LotCollectionToJson(LotCollection instance) =>
    <String, dynamic>{'data': instance.data};
