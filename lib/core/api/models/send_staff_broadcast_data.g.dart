// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_staff_broadcast_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendStaffBroadcastData _$SendStaffBroadcastDataFromJson(
  Map<String, dynamic> json,
) => SendStaffBroadcastData(
  id: json['id'] as String?,
  recipientCount: (json['recipient_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$SendStaffBroadcastDataToJson(
  SendStaffBroadcastData instance,
) => <String, dynamic>{
  'id': instance.id,
  'recipient_count': instance.recipientCount,
};
