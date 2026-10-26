// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receiving_calendar_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivingCalendarCollection _$ReceivingCalendarCollectionFromJson(
  Map<String, dynamic> json,
) => ReceivingCalendarCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => ReceivingDockDay.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReceivingCalendarCollectionToJson(
  ReceivingCalendarCollection instance,
) => <String, dynamic>{'data': instance.data};
