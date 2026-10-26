// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asn_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AsnCollection _$AsnCollectionFromJson(Map<String, dynamic> json) =>
    AsnCollection(
      data: (json['data'] as List<dynamic>)
          .map((e) => Asn.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AsnCollectionToJson(AsnCollection instance) =>
    <String, dynamic>{'data': instance.data};
