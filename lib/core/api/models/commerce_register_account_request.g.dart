// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_register_account_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceRegisterAccountRequest _$CommerceRegisterAccountRequestFromJson(
  Map<String, dynamic> json,
) => CommerceRegisterAccountRequest(
  type: CommerceRegisterAccountRequestType.fromJson(json['type'] as String),
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  taxId: json['tax_id'] as String?,
);

Map<String, dynamic> _$CommerceRegisterAccountRequestToJson(
  CommerceRegisterAccountRequest instance,
) => <String, dynamic>{
  'type': instance.type,
  'user_id': instance.userId,
  'display_name': instance.displayName,
  'tax_id': instance.taxId,
};
