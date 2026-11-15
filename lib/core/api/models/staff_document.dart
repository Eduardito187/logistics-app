// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_document_side.dart';
import 'staff_document_source.dart';

part 'staff_document.g.dart';

@JsonSerializable()
class StaffDocument {
  const StaffDocument({
    this.id,
    this.source,
    this.documentType,
    this.reference,
    this.issuedOn,
    this.expiresOn,
    this.expired,
    this.note,
    this.side,
    this.mimeType,
    this.url,
    this.createdAt,
  });

  factory StaffDocument.fromJson(Map<String, Object?> json) =>
      _$StaffDocumentFromJson(json);

  final String? id;

  /// staff = subido a la ficha; fleet = de su ficha de chofer
  final StaffDocumentSource? source;
  @JsonKey(name: 'document_type')
  final String? documentType;
  final String? reference;
  @JsonKey(name: 'issued_on')
  final DateTime? issuedOn;
  @JsonKey(name: 'expires_on')
  final DateTime? expiresOn;
  final bool? expired;
  final String? note;

  /// Cara del documento; null si es de una sola cara (y siempre null en source=fleet / kind=profile).
  final StaffDocumentSide? side;
  @JsonKey(name: 'mime_type')
  final String? mimeType;

  /// Enlace temporal para ver el archivo
  final String? url;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$StaffDocumentToJson(this);
}
