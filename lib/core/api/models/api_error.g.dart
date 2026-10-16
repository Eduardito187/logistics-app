// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) =>
    ApiError(error: Error.fromJson(json['error'] as Map<String, dynamic>));

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
  'error': instance.error,
};
