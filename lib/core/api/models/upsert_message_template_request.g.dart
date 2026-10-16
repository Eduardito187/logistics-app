// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upsert_message_template_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpsertMessageTemplateRequest _$UpsertMessageTemplateRequestFromJson(
  Map<String, dynamic> json,
) => UpsertMessageTemplateRequest(
  messageType: MessageType.fromJson(json['message_type'] as String),
  channel: Channel.fromJson(json['channel'] as String),
  body: json['body'] as String,
  subject: json['subject'] as String?,
  locale: json['locale'] as String? ?? 'es',
);

Map<String, dynamic> _$UpsertMessageTemplateRequestToJson(
  UpsertMessageTemplateRequest instance,
) => <String, dynamic>{
  'message_type': instance.messageType,
  'channel': instance.channel,
  'locale': instance.locale,
  'subject': instance.subject,
  'body': instance.body,
};
