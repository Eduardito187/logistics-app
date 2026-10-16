// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'verify_label_request.g.dart';

@JsonSerializable()
class VerifyLabelRequest {
  const VerifyLabelRequest({
    required this.payload,
    required this.signature,
    required this.keyId,
  });

  factory VerifyLabelRequest.fromJson(Map<String, Object?> json) =>
      _$VerifyLabelRequestFromJson(json);

  /// JSON canónico del QR (exactamente lo que se firmó)
  final String payload;

  /// Firma de la etiqueta en base64url
  final String signature;

  /// Id de la clave pública con la que se firmó (campo "k" del QR)
  @JsonKey(name: 'key_id')
  final int keyId;

  Map<String, Object?> toJson() => _$VerifyLabelRequestToJson(this);
}
