// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationListEnvelope _$NotificationListEnvelopeFromJson(
  Map<String, dynamic> json,
) => NotificationListEnvelope(
  data: (json['data'] as List<dynamic>)
      .map((e) => NotificationView.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NotificationListEnvelopeToJson(
  NotificationListEnvelope instance,
) => <String, dynamic>{'data': instance.data};
