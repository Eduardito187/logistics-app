// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_setting_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetSettingRequest _$SetSettingRequestFromJson(Map<String, dynamic> json) =>
    SetSettingRequest(
      key: json['key'] as String,
      value: json['value'],
      effectiveFrom: json['effective_from'] == null
          ? null
          : DateTime.parse(json['effective_from'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$SetSettingRequestToJson(SetSettingRequest instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'effective_from': instance.effectiveFrom?.toIso8601String(),
      'created_by': instance.createdBy,
    };
