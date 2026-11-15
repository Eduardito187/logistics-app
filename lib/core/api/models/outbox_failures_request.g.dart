// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_failures_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboxFailuresRequest _$OutboxFailuresRequestFromJson(
  Map<String, dynamic> json,
) => OutboxFailuresRequest(
  failures: (json['failures'] as List<dynamic>)
      .map((e) => Failures.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OutboxFailuresRequestToJson(
  OutboxFailuresRequest instance,
) => <String, dynamic>{'failures': instance.failures};
