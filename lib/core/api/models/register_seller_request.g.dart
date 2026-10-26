// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_seller_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterSellerRequest _$RegisterSellerRequestFromJson(
  Map<String, dynamic> json,
) => RegisterSellerRequest(
  legalName: json['legal_name'] as String,
  taxId: json['tax_id'] as String,
  contactName: json['contact_name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$RegisterSellerRequestToJson(
  RegisterSellerRequest instance,
) => <String, dynamic>{
  'legal_name': instance.legalName,
  'tax_id': instance.taxId,
  'contact_name': instance.contactName,
  'email': instance.email,
  'phone': instance.phone,
};
