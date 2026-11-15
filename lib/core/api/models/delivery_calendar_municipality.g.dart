// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_calendar_municipality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryCalendarMunicipality _$DeliveryCalendarMunicipalityFromJson(
  Map<String, dynamic> json,
) => DeliveryCalendarMunicipality(
  id: json['id'] as String,
  name: json['name'] as String,
  label: json['label'] as String,
  departmentId: json['department_id'] as String?,
  departmentName: json['department_name'] as String?,
);

Map<String, dynamic> _$DeliveryCalendarMunicipalityToJson(
  DeliveryCalendarMunicipality instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'department_id': instance.departmentId,
  'department_name': instance.departmentName,
  'label': instance.label,
};
