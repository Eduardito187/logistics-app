// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxMessage _$OutboxMessageFromJson(Map<String, dynamic> json) =>
    OutboxMessage(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      aggregateType: json['aggregate_type'] as String,
      aggregateId: json['aggregate_id'] as String,
      eventName: json['event_name'] as String,
      payload: json['payload'],
      status: OutboxStatus.fromJson(json['status'] as String),
      attempts: (json['attempts'] as num).toInt(),
      availableAt: DateTime.parse(json['available_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      dispatchedAt: json['dispatched_at'] == null
          ? null
          : DateTime.parse(json['dispatched_at'] as String),
      lastError: json['last_error'] as String?,
    );

Map<String, dynamic> _$OutboxMessageToJson(OutboxMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'aggregate_type': instance.aggregateType,
      'aggregate_id': instance.aggregateId,
      'event_name': instance.eventName,
      'payload': instance.payload,
      'status': instance.status,
      'attempts': instance.attempts,
      'available_at': instance.availableAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'dispatched_at': instance.dispatchedAt?.toIso8601String(),
      'last_error': instance.lastError,
    };
