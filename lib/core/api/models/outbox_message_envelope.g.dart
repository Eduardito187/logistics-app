// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_message_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxMessageEnvelope _$OutboxMessageEnvelopeFromJson(
  Map<String, dynamic> json,
) => OutboxMessageEnvelope(
  data: OutboxMessage.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OutboxMessageEnvelopeToJson(
  OutboxMessageEnvelope instance,
) => <String, dynamic>{'data': instance.data};
