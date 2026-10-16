// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_me_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppMeResponse _$AppMeResponseFromJson(Map<String, dynamic> json) =>
    AppMeResponse(
      user: AppUserProfile.fromJson(json['user'] as Map<String, dynamic>),
      device: json['device'] == null
          ? null
          : AppDevicePayload.fromJson(json['device'] as Map<String, dynamic>),
      abilities: (json['abilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AppMeResponseToJson(AppMeResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
      'device': instance.device,
      'abilities': instance.abilities,
    };
