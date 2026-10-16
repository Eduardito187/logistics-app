// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LabelCollection _$LabelCollectionFromJson(Map<String, dynamic> json) =>
    LabelCollection(
      data: (json['data'] as List<dynamic>)
          .map((e) => EmittedLabel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LabelCollectionToJson(LabelCollection instance) =>
    <String, dynamic>{'data': instance.data};
