// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceAccount _$CommerceAccountFromJson(Map<String, dynamic> json) =>
    CommerceAccount(
      id: json['id'] as String,
      type: CommerceAccountType.fromJson(json['type'] as String),
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      status: json['status'] as String,
      addresses: (json['addresses'] as List<dynamic>)
          .map((e) => CommerceAddress.fromJson(e as Map<String, dynamic>))
          .toList(),
      taxId: json['tax_id'] as String?,
    );

Map<String, dynamic> _$CommerceAccountToJson(CommerceAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'tax_id': instance.taxId,
      'status': instance.status,
      'addresses': instance.addresses,
    };
