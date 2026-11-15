// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_add_address_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceAddAddressRequest _$CommerceAddAddressRequestFromJson(
  Map<String, dynamic> json,
) => CommerceAddAddressRequest(
  label: json['label'] as String,
  recipient: json['recipient'] as String,
  line1: json['line1'] as String,
  city: json['city'] as String,
  line2: json['line2'] as String?,
  state: json['state'] as String?,
  phone: json['phone'] as String?,
  isDefault: json['is_default'] as bool?,
);

Map<String, dynamic> _$CommerceAddAddressRequestToJson(
  CommerceAddAddressRequest instance,
) => <String, dynamic>{
  'label': instance.label,
  'recipient': instance.recipient,
  'line1': instance.line1,
  'line2': instance.line2,
  'city': instance.city,
  'state': instance.state,
  'phone': instance.phone,
  'is_default': instance.isDefault,
};
