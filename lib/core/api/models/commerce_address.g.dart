// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceAddress _$CommerceAddressFromJson(Map<String, dynamic> json) =>
    CommerceAddress(
      label: json['label'] as String,
      recipient: json['recipient'] as String,
      line1: json['line1'] as String,
      city: json['city'] as String,
      isDefault: json['is_default'] as bool,
      line2: json['line2'] as String?,
      state: json['state'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$CommerceAddressToJson(CommerceAddress instance) =>
    <String, dynamic>{
      'label': instance.label,
      'recipient': instance.recipient,
      'line1': instance.line1,
      'line2': instance.line2,
      'city': instance.city,
      'state': instance.state,
      'phone': instance.phone,
      'is_default': instance.isDefault,
    };
