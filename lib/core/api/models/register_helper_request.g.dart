// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_helper_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterHelperRequest _$RegisterHelperRequestFromJson(
  Map<String, dynamic> json,
) => RegisterHelperRequest(
  name: json['name'] as String,
  active: json['active'] as bool? ?? true,
  phone: json['phone'] as String?,
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => DocumentExpiry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RegisterHelperRequestToJson(
  RegisterHelperRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'phone': instance.phone,
  'active': instance.active,
  'documents': instance.documents,
};
