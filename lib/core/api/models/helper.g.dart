// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'helper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Helper _$HelperFromJson(Map<String, dynamic> json) => Helper(
  id: json['id'] as String?,
  name: json['name'] as String?,
  phone: json['phone'] as String?,
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => DocumentExpiry.fromJson(e as Map<String, dynamic>))
      .toList(),
  active: json['active'] as bool?,
);

Map<String, dynamic> _$HelperToJson(Helper instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'documents': instance.documents,
  'active': instance.active,
};
