// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expiring_document_owner_type.dart';

part 'expiring_document.g.dart';

@JsonSerializable()
class ExpiringDocument {
  const ExpiringDocument({
    this.ownerType,
    this.ownerId,
    this.ownerLabel,
    this.documentType,
    this.expiresOn,
    this.expired,
  });

  factory ExpiringDocument.fromJson(Map<String, Object?> json) =>
      _$ExpiringDocumentFromJson(json);

  @JsonKey(name: 'owner_type')
  final ExpiringDocumentOwnerType? ownerType;
  @JsonKey(name: 'owner_id')
  final String? ownerId;

  /// Plate for vehicles, name for drivers.
  @JsonKey(name: 'owner_label')
  final String? ownerLabel;
  @JsonKey(name: 'document_type')
  final String? documentType;
  @JsonKey(name: 'expires_on')
  final DateTime? expiresOn;
  final bool? expired;

  Map<String, Object?> toJson() => _$ExpiringDocumentToJson(this);
}
