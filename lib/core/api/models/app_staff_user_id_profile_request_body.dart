// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_staff_user_id_profile_request_body.g.dart';

@JsonSerializable()
class AppStaffUserIdProfileRequestBody {
  const AppStaffUserIdProfileRequestBody({
    this.phone,
    this.phoneSecondary,
    this.nationalId,
    this.birthDate,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
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

  Map<String, Object?> toJson() =>
      _$AppStaffUserIdProfileRequestBodyToJson(this);
}
