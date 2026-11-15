// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_auth_login_response_sealed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PostAppAuthLoginResponseSealedToJson(
  PostAppAuthLoginResponseSealed instance,
) => <String, dynamic>{};

PostAppAuthLoginResponseSealedAppLoginResponse
_$PostAppAuthLoginResponseSealedAppLoginResponseFromJson(
  Map<String, dynamic> json,
) => PostAppAuthLoginResponseSealedAppLoginResponse(
  token: json['token'] as String,
  tokenType: json['tokenType'] as String,
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  user: AppUserProfile.fromJson(json['user'] as Map<String, dynamic>),
  device: AppDevicePayload.fromJson(json['device'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostAppAuthLoginResponseSealedAppLoginResponseToJson(
  PostAppAuthLoginResponseSealedAppLoginResponse instance,
) => <String, dynamic>{
  'token': instance.token,
  'tokenType': instance.tokenType,
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'user': instance.user,
  'device': instance.device,
};

PostAppAuthLoginResponseSealedTwoFactorChallenge
_$PostAppAuthLoginResponseSealedTwoFactorChallengeFromJson(
  Map<String, dynamic> json,
) => PostAppAuthLoginResponseSealedTwoFactorChallenge(
  twoFactorRequired: json['twoFactorRequired'] as bool,
  challengeId: json['challengeId'] as String,
  expiresIn: (json['expiresIn'] as num).toInt(),
);

Map<String, dynamic> _$PostAppAuthLoginResponseSealedTwoFactorChallengeToJson(
  PostAppAuthLoginResponseSealedTwoFactorChallenge instance,
) => <String, dynamic>{
  'twoFactorRequired': instance.twoFactorRequired,
  'challengeId': instance.challengeId,
  'expiresIn': instance.expiresIn,
};
