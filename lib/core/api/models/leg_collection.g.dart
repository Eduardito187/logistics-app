// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leg_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegCollection _$LegCollectionFromJson(Map<String, dynamic> json) =>
    LegCollection(
      data: (json['data'] as List<dynamic>)
          .map((e) => Leg.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: Meta11.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LegCollectionToJson(LegCollection instance) =>
    <String, dynamic>{'data': instance.data, 'meta': instance.meta};
