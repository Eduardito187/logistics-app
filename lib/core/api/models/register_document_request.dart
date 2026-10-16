// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_owner_type.dart';

part 'register_document_request.g.dart';

@JsonSerializable()
class RegisterDocumentRequest {
  const RegisterDocumentRequest({
    required this.ownerType,
    required this.ownerId,
    required this.documentType,
    required this.expiresOn,
    this.issuedOn,
    this.filePath,
    this.note,
    this.reference,
  });

  factory RegisterDocumentRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterDocumentRequestFromJson(json);

  @JsonKey(name: 'owner_type')
  final DocumentOwnerType ownerType;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @JsonKey(name: 'document_type')
  final String documentType;
  @JsonKey(name: 'expires_on')
  final DateTime expiresOn;
  @JsonKey(name: 'issued_on')
  final DateTime? issuedOn;
  @JsonKey(name: 'file_path')
  final String? filePath;
  final String? note;

  /// Policy/serial number (SOAT) or certificate number (technical inspection).
  final String? reference;

  Map<String, Object?> toJson() => _$RegisterDocumentRequestToJson(this);
}
