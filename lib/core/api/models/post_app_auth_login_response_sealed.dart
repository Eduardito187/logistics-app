// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_device_payload.dart';
import 'app_user_profile.dart';
import 'app_login_response.dart';
import 'two_factor_challenge.dart';

part 'post_app_auth_login_response_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class PostAppAuthLoginResponseSealed {
  const PostAppAuthLoginResponseSealed();

  factory PostAppAuthLoginResponseSealed.fromJson(Map<String, dynamic> json) =>
      PostAppAuthLoginResponseSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension PostAppAuthLoginResponseSealedDeserializer
    on PostAppAuthLoginResponseSealed {
  static PostAppAuthLoginResponseSealed tryDeserialize(
    Map<String, dynamic> json,
  ) {
    try {
      return PostAppAuthLoginResponseSealedAppLoginResponse.fromJson(json);
    } catch (_) {}
    try {
      return PostAppAuthLoginResponseSealedTwoFactorChallenge.fromJson(json);
    } catch (_) {}

    throw FormatException(
      'Could not determine the correct type for PostAppAuthLoginResponseSealed from: $json',
    );
  }
}

@JsonSerializable()
class PostAppAuthLoginResponseSealedAppLoginResponse
    extends PostAppAuthLoginResponseSealed
    implements AppLoginResponse {
  @override
  final String token;
  @override
  final String tokenType;
  @override
  final DateTime? expiresAt;
  @override
  final AppUserProfile user;
  @override
  final AppDevicePayload device;

  const PostAppAuthLoginResponseSealedAppLoginResponse({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.user,
    required this.device,
  });

  factory PostAppAuthLoginResponseSealedAppLoginResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$PostAppAuthLoginResponseSealedAppLoginResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$PostAppAuthLoginResponseSealedAppLoginResponseToJson(this);
}

@JsonSerializable()
class PostAppAuthLoginResponseSealedTwoFactorChallenge
    extends PostAppAuthLoginResponseSealed
    implements TwoFactorChallenge {
  @override
  final bool twoFactorRequired;
  @override
  final String challengeId;
  @override
  final int expiresIn;

  const PostAppAuthLoginResponseSealedTwoFactorChallenge({
    required this.twoFactorRequired,
    required this.challengeId,
    required this.expiresIn,
  });

  factory PostAppAuthLoginResponseSealedTwoFactorChallenge.fromJson(
    Map<String, dynamic> json,
  ) => _$PostAppAuthLoginResponseSealedTwoFactorChallengeFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$PostAppAuthLoginResponseSealedTwoFactorChallengeToJson(this);
}
