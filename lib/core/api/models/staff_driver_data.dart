// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'staff_driver_data.g.dart';

/// Datos de chofer; null si la persona no es chofer
@JsonSerializable()
class StaffDriverData {
  const StaffDriverData({
    this.id,
    this.active,
    this.licenseNumber,
    this.licenseCategory,
    this.licenseExpiry,
    this.licenseExpired,
    this.birthDate,
    this.phoneSecondary,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory StaffDriverData.fromJson(Map<String, Object?> json) =>
      _$StaffDriverDataFromJson(json);

  final String? id;
  final bool? active;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  @JsonKey(name: 'license_category')
  final String? licenseCategory;
  @JsonKey(name: 'license_expiry')
  final DateTime? licenseExpiry;
  @JsonKey(name: 'license_expired')
  final bool? licenseExpired;
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;
  @JsonKey(name: 'phone_secondary')
  final String? phoneSecondary;
  final String? address;
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  Map<String, Object?> toJson() => _$StaffDriverDataToJson(this);
}
