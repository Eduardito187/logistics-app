// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicUnit _$PublicUnitFromJson(Map<String, dynamic> json) => PublicUnit(
  label: json['label'] as String,
  status: UnitStatus.fromJson(json['status'] as String),
  statusMessage: json['status_message'] as String,
);

Map<String, dynamic> _$PublicUnitToJson(PublicUnit instance) =>
    <String, dynamic>{
      'label': instance.label,
      'status': instance.status,
      'status_message': instance.statusMessage,
    };
