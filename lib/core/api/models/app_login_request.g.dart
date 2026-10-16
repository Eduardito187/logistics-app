// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppLoginRequest _$AppLoginRequestFromJson(Map<String, dynamic> json) =>
    AppLoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      device: Device.fromJson(json['device'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppLoginRequestToJson(AppLoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'device': instance.device,
    };
