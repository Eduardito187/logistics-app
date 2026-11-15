// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_inbox_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffInboxItem _$StaffInboxItemFromJson(Map<String, dynamic> json) =>
    StaffInboxItem(
      kind: json['kind'] == null
          ? null
          : StaffInboxItemKind.fromJson(json['kind'] as String),
      severity: json['severity'] as String?,
      id: json['id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      link: json['link'] as String?,
      sentAt: json['sent_at'] == null
          ? null
          : DateTime.parse(json['sent_at'] as String),
      read: json['read'] as bool?,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );

Map<String, dynamic> _$StaffInboxItemToJson(StaffInboxItem instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'severity': instance.severity,
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'link': instance.link,
      'sent_at': instance.sentAt?.toIso8601String(),
      'read': instance.read,
      'read_at': instance.readAt?.toIso8601String(),
    };
