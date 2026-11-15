// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'destination2.dart';
import 'origin.dart';
import 'piece.dart';
import 'unit.dart';

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
    this.productName,
    this.imageUrl,
    this.origin,
    this.destination,
    this.unitId,
    this.shipmentId,
    this.unit,
    this.piece,
  });

  factory EmittedLabel.fromJson(Map<String, Object?> json) =>
      _$EmittedLabelFromJson(json);

  @JsonKey(name: 'order_number')
  final String orderNumber;

  /// Identidad de negocio (campo `id` del payload), única por producto físico
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

  /// Marca de tiempo de emisión (epoch en segundos). Las etiquetas son permanentes.
  @JsonKey(name: 'emitted_at')
  final int emittedAt;

  /// Nombre humano del producto, resuelto por SKU (líneas del envío / catálogo). null si no se pudo resolver.
  @JsonKey(name: 'product_name')
  final String? productName;

  /// URL servible ABSOLUTA de la imagen del producto (resuelta por SKU). null si no hay imagen.
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Origen de despacho. `code` es el código embebido en el QR; `name` es el nombre de nodo si el código matchea la red.
  final Origin? origin;

  /// Destino del envío de la orden (nombres humanos, sin uuid).
  final Destination2? destination;

  /// UUID del PRODUCTO FÍSICO (shipment_units) de esta etiqueta, resuelto por correlación. La app mapea label_id→unit_id localmente (offline) para escanear. Mismo valor que UnitTracking.unit_id. null si no se pudo atar.
  @JsonKey(name: 'unit_id')
  final String? unitId;

  /// UUID del envío del producto (opaco), o null
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  final Unit? unit;
  final Piece? piece;

  Map<String, Object?> toJson() => _$EmittedLabelToJson(this);
}
