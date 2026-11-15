// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_register_document_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetRegisterDocumentData _$FleetRegisterDocumentDataFromJson(
  Map<String, dynamic> json,
) => FleetRegisterDocumentData(
  status: json['status'] as String?,
  ownerType: json['owner_type'] == null
      ? null
      : DocumentOwnerType.fromJson(json['owner_type'] as String),
  ownerId: json['owner_id'] as String?,
  documentType: json['document_type'] as String?,
);

Map<String, dynamic> _$FleetRegisterDocumentDataToJson(
  FleetRegisterDocumentData instance,
) => <String, dynamic>{
  'status': instance.status,
  'owner_type': instance.ownerType,
  'owner_id': instance.ownerId,
  'document_type': instance.documentType,
};
