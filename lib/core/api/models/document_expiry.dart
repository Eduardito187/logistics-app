// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'document_expiry.g.dart';

@JsonSerializable()
class DocumentExpiry {
  const DocumentExpiry({required this.type, required this.expiresOn});

  factory DocumentExpiry.fromJson(Map<String, Object?> json) =>
      _$DocumentExpiryFromJson(json);

  final String type;
  @JsonKey(name: 'expires_on')
  final DateTime expiresOn;

  Map<String, Object?> toJson() => _$DocumentExpiryToJson(this);
}
