// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data14.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data14 _$Data14FromJson(Map<String, dynamic> json) => Data14(
  status: json['status'] as String?,
  ownerType: json['owner_type'] == null
      ? null
      : DocumentOwnerType.fromJson(json['owner_type'] as String),
  ownerId: json['owner_id'] as String?,
  documentType: json['document_type'] as String?,
);

Map<String, dynamic> _$Data14ToJson(Data14 instance) => <String, dynamic>{
  'status': instance.status,
  'owner_type': instance.ownerType,
  'owner_id': instance.ownerId,
  'document_type': instance.documentType,
};
