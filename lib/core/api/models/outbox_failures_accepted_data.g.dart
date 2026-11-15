// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_failures_accepted_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxFailuresAcceptedData _$OutboxFailuresAcceptedDataFromJson(
  Map<String, dynamic> json,
) => OutboxFailuresAcceptedData(
  accepted: json['accepted'] as bool,
  received: (json['received'] as num?)?.toInt(),
  stored: (json['stored'] as num?)?.toInt(),
  duplicates: (json['duplicates'] as num?)?.toInt(),
);

Map<String, dynamic> _$OutboxFailuresAcceptedDataToJson(
  OutboxFailuresAcceptedData instance,
) => <String, dynamic>{
  'accepted': instance.accepted,
  'received': instance.received,
  'stored': instance.stored,
  'duplicates': instance.duplicates,
};
