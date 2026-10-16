// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'emitted_label.g.dart';

@JsonSerializable()
class EmittedLabel {
  const EmittedLabel({
    required this.orderNumber,
    required this.labelId,
    required this.keyId,
    required this.sku,
    required this.lineNumber,
    required this.qrContent,
    required this.zpl,
    required this.emittedAt,
    required this.revoked,
    this.revokedAt,
    this.revokedReason,
  });

  factory EmittedLabel.fromJson(Map<String, Object?> json) =>
      _$EmittedLabelFromJson(json);

  @JsonKey(name: 'order_number')
  final String orderNumber;

  /// Identidad de negocio (campo `id` del payload), única por bulto físico
  @JsonKey(name: 'label_id')
  final String labelId;

  /// Clave con la que se firmó (campo `k` del QR)
  @JsonKey(name: 'key_id')
  final int keyId;
  final String sku;
  @JsonKey(name: 'line_number')
  final int lineNumber;

  /// JSON firmado exacto que lleva el QR
  @JsonKey(name: 'qr_content')
  final String qrContent;

  /// Representación ZPL para la impresora Zebra
  final String zpl;

  /// Marca de tiempo de emisión (epoch en segundos)
  @JsonKey(name: 'emitted_at')
  final int emittedAt;

  /// true si la etiqueta fue revocada (p. ej. por reimpresión) y ya no es válida
  final bool revoked;

  /// Marca de tiempo de revocación (epoch en segundos), o null si está vigente
  @JsonKey(name: 'revoked_at')
  final int? revokedAt;

  /// Motivo de la revocación, o null si está vigente
  @JsonKey(name: 'revoked_reason')
  final String? revokedReason;

  Map<String, Object?> toJson() => _$EmittedLabelToJson(this);
}
