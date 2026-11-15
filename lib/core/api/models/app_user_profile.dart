// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_user_carrier.dart';
import 'node.dart';

part 'app_user_profile.g.dart';

@JsonSerializable()
class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.node,
    this.carrier,
  });

  factory AppUserProfile.fromJson(Map<String, Object?> json) =>
      _$AppUserProfileFromJson(json);

  /// User primary key (auto-increment).
  final int id;
  final String name;
  final String email;
  final List<String> roles;

  /// Store node the account belongs to, or null for roles without a store.
  final Node? node;

  /// Carrier the account belongs to (server-side identity of the carrier role, users.carrier_id), or null for non-carrier roles / unlinked accounts. The app must read it from here instead of letting the user pick a carrier.
  final AppUserCarrier? carrier;

  Map<String, Object?> toJson() => _$AppUserProfileToJson(this);
}
