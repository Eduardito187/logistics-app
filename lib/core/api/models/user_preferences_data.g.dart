// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreferencesData _$UserPreferencesDataFromJson(Map<String, dynamic> json) =>
    UserPreferencesData(
      preferences: json['preferences'],
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      ignoredKeys: (json['ignored_keys'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UserPreferencesDataToJson(
  UserPreferencesData instance,
) => <String, dynamic>{
  'preferences': instance.preferences,
  'updated_at': instance.updatedAt?.toIso8601String(),
  'ignored_keys': instance.ignoredKeys,
};
