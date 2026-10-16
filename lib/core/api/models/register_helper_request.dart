// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_expiry.dart';

part 'register_helper_request.g.dart';

@JsonSerializable()
class RegisterHelperRequest {
  const RegisterHelperRequest({
    required this.name,
    this.active = true,
    this.phone,
    this.documents,
  });

  factory RegisterHelperRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterHelperRequestFromJson(json);

  final String name;
  final String? phone;
  final bool active;
  final List<DocumentExpiry>? documents;

  Map<String, Object?> toJson() => _$RegisterHelperRequestToJson(this);
}
