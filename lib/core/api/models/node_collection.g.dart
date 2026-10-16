// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeCollection _$NodeCollectionFromJson(Map<String, dynamic> json) =>
    NodeCollection(
      data: (json['data'] as List<dynamic>)
          .map((e) => Node.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: Meta13.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NodeCollectionToJson(NodeCollection instance) =>
    <String, dynamic>{'data': instance.data, 'meta': instance.meta};
