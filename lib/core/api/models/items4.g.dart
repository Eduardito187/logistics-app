// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items4.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Items4 _$Items4FromJson(Map<String, dynamic> json) => Items4(
  idempotencyKey: json['idempotency_key'] as String,
  kind: Kind.fromJson(json['kind'] as String),
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  payload: json['payload'],
);

Map<String, dynamic> _$Items4ToJson(Items4 instance) => <String, dynamic>{
  'idempotency_key': instance.idempotencyKey,
  'kind': instance.kind,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'payload': instance.payload,
};
