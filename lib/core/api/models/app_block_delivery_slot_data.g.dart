// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_block_delivery_slot_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppBlockDeliverySlotData _$AppBlockDeliverySlotDataFromJson(
  Map<String, dynamic> json,
) => AppBlockDeliverySlotData(
  status: json['status'] as String?,
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  timeSlot: json['time_slot'] as String?,
  municipalityId: json['municipality_id'] as String?,
  blocked: json['blocked'] as bool?,
);

Map<String, dynamic> _$AppBlockDeliverySlotDataToJson(
  AppBlockDeliverySlotData instance,
) => <String, dynamic>{
  'status': instance.status,
  'date': instance.date?.toIso8601String(),
  'time_slot': instance.timeSlot,
  'municipality_id': instance.municipalityId,
  'blocked': instance.blocked,
};
