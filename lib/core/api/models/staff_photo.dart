// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_document_side.dart';
import 'staff_photo_kind.dart';

part 'staff_photo.g.dart';

@JsonSerializable()
class StaffPhoto {
  const StaffPhoto({this.kind, this.url, this.at, this.label, this.side});

  factory StaffPhoto.fromJson(Map<String, Object?> json) =>
      _$StaffPhotoFromJson(json);

  /// La evidencia de entregas pertenece al pedido y no se lista acá.
  final StaffPhotoKind? kind;
  final String? url;
  final DateTime? at;
  final String? label;

  /// Cara del documento; null si es de una sola cara (y siempre null en source=fleet / kind=profile).
  final StaffDocumentSide? side;

  Map<String, Object?> toJson() => _$StaffPhotoToJson(this);
}
