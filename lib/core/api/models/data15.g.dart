// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data15.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data15 _$Data15FromJson(Map<String, dynamic> json) => Data15(
  status: json['status'] as String?,
  ownerType: json['owner_type'] == null
      ? null
      : DocumentOwnerType.fromJson(json['owner_type'] as String),
  ownerId: json['owner_id'] as String?,
  documentType: json['document_type'] as String?,
);

Map<String, dynamic> _$Data15ToJson(Data15 instance) => <String, dynamic>{
  'status': instance.status,
  'owner_type': instance.ownerType,
  'owner_id': instance.ownerId,
  'document_type': instance.documentType,
};
