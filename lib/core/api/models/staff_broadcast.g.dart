// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_broadcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffBroadcast _$StaffBroadcastFromJson(Map<String, dynamic> json) =>
    StaffBroadcast(
      id: json['id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      link: json['link'] as String?,
      sentAt: json['sent_at'] == null
          ? null
          : DateTime.parse(json['sent_at'] as String),
      audience: json['audience'],
      recipientCount: (json['recipient_count'] as num?)?.toInt(),
      readCount: (json['read_count'] as num?)?.toInt(),
      sentBy: json['sent_by'] == null
          ? null
          : SentBy.fromJson(json['sent_by'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StaffBroadcastToJson(StaffBroadcast instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'link': instance.link,
      'sent_at': instance.sentAt?.toIso8601String(),
      'audience': instance.audience,
      'recipient_count': instance.recipientCount,
      'read_count': instance.readCount,
      'sent_by': instance.sentBy,
    };
