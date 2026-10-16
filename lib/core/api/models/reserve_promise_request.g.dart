// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserve_promise_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReservePromiseRequest _$ReservePromiseRequestFromJson(
  Map<String, dynamic> json,
) => ReservePromiseRequest(ttlMinutes: (json['ttl_minutes'] as num).toInt());

Map<String, dynamic> _$ReservePromiseRequestToJson(
  ReservePromiseRequest instance,
) => <String, dynamic>{'ttl_minutes': instance.ttlMinutes};
