// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'staff_personal_data.g.dart';

/// Datos personales de la persona (cualquier rol). Teléfono principal, documento y foto van en la raíz de la ficha.
@JsonSerializable()
class StaffPersonalData {
  const StaffPersonalData({
    this.phoneSecondary,
    this.birthDate,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory StaffPersonalData.fromJson(Map<String, Object?> json) =>
      _$StaffPersonalDataFromJson(json);

  @JsonKey(name: 'phone_secondary')
  final String? phoneSecondary;
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;
  final String? address;
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  Map<String, Object?> toJson() => _$StaffPersonalDataToJson(this);
}
