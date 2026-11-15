// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'two_factor_challenge.g.dart';

@JsonSerializable()
class TwoFactorChallenge {
  const TwoFactorChallenge({
    required this.twoFactorRequired,
    required this.challengeId,
    required this.expiresIn,
  });

  factory TwoFactorChallenge.fromJson(Map<String, Object?> json) =>
      _$TwoFactorChallengeFromJson(json);

  @JsonKey(name: 'two_factor_required')
  final bool twoFactorRequired;

  /// Identificador del desafío a resolver en /app/auth/2fa/verify.
  @JsonKey(name: 'challenge_id')
  final String challengeId;

  /// Segundos hasta que el desafío expira.
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  Map<String, Object?> toJson() => _$TwoFactorChallengeToJson(this);
}
