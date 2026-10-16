// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operational_corridor_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperationalCorridorCollection _$OperationalCorridorCollectionFromJson(
  Map<String, dynamic> json,
) => OperationalCorridorCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => OperationalCorridor.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: Meta14.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OperationalCorridorCollectionToJson(
  OperationalCorridorCollection instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
