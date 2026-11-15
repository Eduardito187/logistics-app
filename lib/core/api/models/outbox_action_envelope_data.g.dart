// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_action_envelope_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxActionEnvelopeData _$OutboxActionEnvelopeDataFromJson(
  Map<String, dynamic> json,
) => OutboxActionEnvelopeData(
  id: json['id'] as String,
  status: OutboxStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$OutboxActionEnvelopeDataToJson(
  OutboxActionEnvelopeData instance,
) => <String, dynamic>{'id': instance.id, 'status': instance.status};
