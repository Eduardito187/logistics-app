// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerContact _$SellerContactFromJson(Map<String, dynamic> json) =>
    SellerContact(
      contactName: json['contact_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$SellerContactToJson(SellerContact instance) =>
    <String, dynamic>{
      'contact_name': instance.contactName,
      'email': instance.email,
      'phone': instance.phone,
    };
