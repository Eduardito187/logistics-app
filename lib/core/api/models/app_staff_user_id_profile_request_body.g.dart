// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_staff_user_id_profile_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppStaffUserIdProfileRequestBody _$AppStaffUserIdProfileRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppStaffUserIdProfileRequestBody(
  phone: json['phone'] as String?,
  phoneSecondary: json['phone_secondary'] as String?,
  nationalId: json['national_id'] as String?,
  birthDate: json['birth_date'] == null
      ? null
      : DateTime.parse(json['birth_date'] as String),
  address: json['address'] as String?,
  emergencyContactName: json['emergency_contact_name'] as String?,
  emergencyContactPhone: json['emergency_contact_phone'] as String?,
  city: json['city'] == null
      ? null
      : Department.fromJson(json['city'] as String),
);

Map<String, dynamic> _$AppStaffUserIdProfileRequestBodyToJson(
  AppStaffUserIdProfileRequestBody instance,
) => <String, dynamic>{
  'phone': instance.phone,
  'phone_secondary': instance.phoneSecondary,
  'national_id': instance.nationalId,
  'birth_date': instance.birthDate?.toIso8601String(),
  'address': instance.address,
  'emergency_contact_name': instance.emergencyContactName,
  'emergency_contact_phone': instance.emergencyContactPhone,
  'city': instance.city,
};
