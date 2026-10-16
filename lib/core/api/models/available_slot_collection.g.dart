// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_slot_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailableSlotCollection _$AvailableSlotCollectionFromJson(
  Map<String, dynamic> json,
) => AvailableSlotCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => AvailableSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: Meta8.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AvailableSlotCollectionToJson(
  AvailableSlotCollection instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
