// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceCart _$CommerceCartFromJson(Map<String, dynamic> json) => CommerceCart(
  id: json['id'] as String,
  sessionId: json['session_id'] as String,
  status: json['status'] as String,
  currency: json['currency'] as String,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => CommerceCartLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCents: (json['total_cents'] as num).toInt(),
  customerId: json['customer_id'] as String?,
);

Map<String, dynamic> _$CommerceCartToJson(CommerceCart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'session_id': instance.sessionId,
      'status': instance.status,
      'currency': instance.currency,
      'lines': instance.lines,
      'total_cents': instance.totalCents,
    };
