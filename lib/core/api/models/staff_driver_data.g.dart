// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_driver_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffDriverData _$StaffDriverDataFromJson(Map<String, dynamic> json) =>
    StaffDriverData(
      id: json['id'] as String?,
      active: json['active'] as bool?,
      licenseNumber: json['license_number'] as String?,
      licenseCategory: json['license_category'] as String?,
      licenseExpiry: json['license_expiry'] == null
          ? null
          : DateTime.parse(json['license_expiry'] as String),
      licenseExpired: json['license_expired'] as bool?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      phoneSecondary: json['phone_secondary'] as String?,
      address: json['address'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
    );

Map<String, dynamic> _$StaffDriverDataToJson(StaffDriverData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'active': instance.active,
      'license_number': instance.licenseNumber,
      'license_category': instance.licenseCategory,
      'license_expiry': instance.licenseExpiry?.toIso8601String(),
      'license_expired': instance.licenseExpired,
      'birth_date': instance.birthDate?.toIso8601String(),
      'phone_secondary': instance.phoneSecondary,
      'address': instance.address,
      'emergency_contact_name': instance.emergencyContactName,
      'emergency_contact_phone': instance.emergencyContactPhone,
    };
