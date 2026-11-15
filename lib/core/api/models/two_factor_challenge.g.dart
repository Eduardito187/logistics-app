// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor_challenge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TwoFactorChallenge _$TwoFactorChallengeFromJson(Map<String, dynamic> json) =>
    TwoFactorChallenge(
      twoFactorRequired: json['two_factor_required'] as bool,
      challengeId: json['challenge_id'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
    );

Map<String, dynamic> _$TwoFactorChallengeToJson(TwoFactorChallenge instance) =>
    <String, dynamic>{
      'two_factor_required': instance.twoFactorRequired,
      'challenge_id': instance.challengeId,
      'expires_in': instance.expiresIn,
    };
