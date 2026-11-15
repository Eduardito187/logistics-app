// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'unit_status.dart';

part 'unit_tracking.g.dart';

/// Vista interna del seguimiento de un producto
@JsonSerializable()
class UnitTracking {
  const UnitTracking({
    required this.id,
    required this.unitId,
    required this.shipmentId,
    required this.status,
    required this.lastLocationId,
    required this.lastSeenAt,
    required this.label,
    this.location,
    this.sku,
    this.productName,
    this.productImageUrl,
    this.pieceIndex,
    this.pieceTotal,
    this.labelId,
  });

  factory UnitTracking.fromJson(Map<String, Object?> json) =>
      _$UnitTrackingFromJson(json);

  /// Current shelf location at the node, if assigned.
  final String? location;
  final String id;
  @JsonKey(name: 'unit_id')
  final String unitId;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final UnitStatus status;

  /// Nodo/parada donde se vio por última vez el producto
  @JsonKey(name: 'last_location_id')
  final String? lastLocationId;
  @JsonKey(name: 'last_seen_at')
  final DateTime? lastSeenAt;

  /// Etiqueta humana del producto ("N/M")
  final String? label;

  /// SKU del producto (null si no se resuelve)
  final String? sku;
  @JsonKey(name: 'product_name')
  final String? productName;
  @JsonKey(name: 'product_image_url')
  final String? productImageUrl;

  /// Pieza N de un producto fraccionado en varias cajas
  @JsonKey(name: 'piece_index')
  final int? pieceIndex;
  @JsonKey(name: 'piece_total')
  final int? pieceTotal;

  /// Id (ULID del QR) de la etiqueta de este producto, para que la app mapee label_id→unit_id offline al escanear. Mismo unit_id que EmittedLabel. null si el producto aún no tiene etiqueta emitida.
  @JsonKey(name: 'label_id')
  final String? labelId;

  Map<String, Object?> toJson() => _$UnitTrackingToJson(this);
}
