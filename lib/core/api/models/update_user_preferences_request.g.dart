// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user_preferences_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUserPreferencesRequest _$UpdateUserPreferencesRequestFromJson(
  Map<String, dynamic> json,
) => UpdateUserPreferencesRequest(
  preferences: json['preferences'],
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UpdateUserPreferencesRequestToJson(
  UpdateUserPreferencesRequest instance,
) => <String, dynamic>{
  'preferences': instance.preferences,
  'updated_at': instance.updatedAt?.toIso8601String(),
};
