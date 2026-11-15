// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'department.dart';

part 'app_staff_user_id_profile_request_body.g.dart';

@JsonSerializable()
class AppStaffUserIdProfileRequestBody {
  const AppStaffUserIdProfileRequestBody({
    required this.phone,
    required this.phoneSecondary,
    required this.nationalId,
    required this.birthDate,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.city,
  });

  factory AppStaffUserIdProfileRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppStaffUserIdProfileRequestBodyFromJson(json);

  final String? phone;
  @JsonKey(name: 'phone_secondary')
  final String? phoneSecondary;
  @JsonKey(name: 'national_id')
  final String? nationalId;
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;
  final String? address;
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  /// Ciudad de la persona: código del catálogo o null para quitarla. Si la persona tiene tienda / nodo debe coincidir con el departamento de ese nodo (422 si no).
  final Department? city;

  Map<String, Object?> toJson() =>
      _$AppStaffUserIdProfileRequestBodyToJson(this);
}
