// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_message_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxMessagePage _$OutboxMessagePageFromJson(Map<String, dynamic> json) =>
    OutboxMessagePage(
      data: (json['data'] as List<dynamic>)
          .map((e) => OutboxMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: Meta15.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OutboxMessagePageToJson(OutboxMessagePage instance) =>
    <String, dynamic>{'data': instance.data, 'meta': instance.meta};
