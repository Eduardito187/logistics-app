// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_ship_to.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceShipTo _$CommerceShipToFromJson(Map<String, dynamic> json) =>
    CommerceShipTo(
      customerName: json['customer_name'] as String,
      addressText: json['address_text'] as String,
      reference: json['reference'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$CommerceShipToToJson(CommerceShipTo instance) =>
    <String, dynamic>{
      'customer_name': instance.customerName,
      'address_text': instance.addressText,
      'reference': instance.reference,
      'phone': instance.phone,
      'email': instance.email,
    };
