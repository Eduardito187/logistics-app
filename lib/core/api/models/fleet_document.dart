// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_owner_type.dart';

part 'fleet_document.g.dart';

@JsonSerializable()
class FleetDocument {
  const FleetDocument({
    this.id,
    this.ownerType,
    this.ownerId,
    this.documentType,
    this.expiresOn,
    this.issuedOn,
    this.filePath,
    this.note,
    this.reference,
  });

  factory FleetDocument.fromJson(Map<String, Object?> json) =>
      _$FleetDocumentFromJson(json);

  final String? id;
  @JsonKey(name: 'owner_type')
  final DocumentOwnerType? ownerType;
  @JsonKey(name: 'owner_id')
  final String? ownerId;
  @JsonKey(name: 'document_type')
  final String? documentType;
  @JsonKey(name: 'expires_on')
  final DateTime? expiresOn;
  @JsonKey(name: 'issued_on')
  final DateTime? issuedOn;

  /// Object key on the private S3 disk (signed on download).
  @JsonKey(name: 'file_path')
  final String? filePath;
  final String? note;

  /// Policy/serial number (SOAT) or certificate number (technical inspection).
  final String? reference;

  Map<String, Object?> toJson() => _$FleetDocumentToJson(this);
}
