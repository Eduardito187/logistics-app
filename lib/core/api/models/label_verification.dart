// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'label_verification_result.dart';

part 'label_verification.g.dart';

@JsonSerializable()
class LabelVerification {
  const LabelVerification({required this.valid, required this.result});

  factory LabelVerification.fromJson(Map<String, Object?> json) =>
      _$LabelVerificationFromJson(json);

  final bool valid;
  final LabelVerificationResult result;

  Map<String, Object?> toJson() => _$LabelVerificationToJson(this);
}
