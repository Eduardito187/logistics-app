// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispatch_destination.dart';
import 'dispatch_line_label_status.dart';
import 'origin2.dart';

part 'dispatch_line.g.dart';

@JsonSerializable()
class DispatchLine {
  const DispatchLine({
    required this.sku,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.piecesPerUnit,
    required this.lineNumber,
    required this.origin,
    required this.destination,
    required this.shipmentId,
    required this.shipmentReference,
    required this.authorized,
    required this.authorizedReason,
    required this.labelStatus,
  });

  factory DispatchLine.fromJson(Map<String, Object?> json) =>
      _$DispatchLineFromJson(json);

  final String sku;
  @JsonKey(name: 'product_name')
  final String? productName;

  /// URL servible absoluta de la imagen del producto, o null
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final int quantity;

  /// Bultos por unidad; 1 por defecto si no se conoce
  @JsonKey(name: 'pieces_per_unit')
  final int piecesPerUnit;

  /// Posición 1-based de la línea en la orden
  @JsonKey(name: 'line_number')
  final int lineNumber;
  final Origin2 origin;
  final DispatchDestination destination;

  /// Clave OPACA de agrupación del envío (no se muestra)
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;

  /// Referencia legible del envío (mostrable como título del grupo)
  @JsonKey(name: 'shipment_reference')
  final String? shipmentReference;

  /// true si el envío está en un plan publicado
  final bool authorized;

  /// Motivo si authorized=false (p. ej. "sin plan publicado")
  @JsonKey(name: 'authorized_reason')
  final String? authorizedReason;
  @JsonKey(name: 'label_status')
  final DispatchLineLabelStatus labelStatus;

  Map<String, Object?> toJson() => _$DispatchLineToJson(this);
}
