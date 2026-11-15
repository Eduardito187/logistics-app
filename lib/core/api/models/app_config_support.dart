// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_config_support.g.dart';

@JsonSerializable()
class AppConfigSupport {
  const AppConfigSupport({this.email, this.phone, this.whatsapp, this.hours});

  factory AppConfigSupport.fromJson(Map<String, Object?> json) =>
      _$AppConfigSupportFromJson(json);

  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? hours;

  Map<String, Object?> toJson() => _$AppConfigSupportToJson(this);
}
