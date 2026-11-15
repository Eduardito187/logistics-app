// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_open_cart_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceOpenCartRequest _$CommerceOpenCartRequestFromJson(
  Map<String, dynamic> json,
) => CommerceOpenCartRequest(
  sessionId: json['session_id'] as String,
  customerId: json['customer_id'] as String?,
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$CommerceOpenCartRequestToJson(
  CommerceOpenCartRequest instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'customer_id': instance.customerId,
  'currency': instance.currency,
};
