// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_issue_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryIssueRequest _$DeliveryIssueRequestFromJson(
  Map<String, dynamic> json,
) => DeliveryIssueRequest(
  type: DeliveryIssueType.fromJson(json['type'] as String),
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  note: json['note'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  photoPath: json['photo_path'] as String?,
  idempotencyKey: json['idempotency_key'] as String?,
);

Map<String, dynamic> _$DeliveryIssueRequestToJson(
  DeliveryIssueRequest instance,
) => <String, dynamic>{
  'type': instance.type,
  'note': instance.note,
  'lat': instance.lat,
  'lng': instance.lng,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'photo_path': instance.photoPath,
  'idempotency_key': instance.idempotencyKey,
};
