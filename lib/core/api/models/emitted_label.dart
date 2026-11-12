// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'destination.dart';
import 'origin.dart';

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
    // Etiquetas PERMANENTES: el backend ya NO manda `revoked` (nada se anula).
    // Queda opcional con default `false` para que la respuesta SIN el campo
    // deserialice (si no, el pedido no carga). Al regenerar el cliente desde el
    // openapi nuevo el campo desaparece solo.
    this.revoked = false,
    this.revokedAt,
    this.revokedReason,
    this.productName,
    this.imageUrl,
    this.origin,
    this.destination,
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

  /// Nombre humano del producto, resuelto por SKU (líneas del envío / catálogo). null si no se pudo resolver.
  @JsonKey(name: 'product_name')
  final String? productName;

  /// URL servible ABSOLUTA de la imagen del producto (resuelta por SKU). null si no hay imagen.
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Origen de despacho. `code` es el código embebido en el QR; `name` es el nombre de nodo si el código matchea la red.
  final Origin? origin;

  /// Destino del envío de la orden (nombres humanos, sin uuid).
  final Destination? destination;

  Map<String, Object?> toJson() => _$EmittedLabelToJson(this);
}
