// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_checkout_accepted.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceCheckoutAccepted _$CommerceCheckoutAcceptedFromJson(
  Map<String, dynamic> json,
) => CommerceCheckoutAccepted(
  accepted: json['accepted'] as bool,
  customerName: json['customer_name'] as String?,
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$CommerceCheckoutAcceptedToJson(
  CommerceCheckoutAccepted instance,
) => <String, dynamic>{
  'accepted': instance.accepted,
  'customer_name': instance.customerName,
  'currency': instance.currency,
};
