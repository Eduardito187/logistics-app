// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_evidence_file.dart';
import 'delivery_status.dart';
import 'failure_reason.dart';
import 'scan_event.dart';
import 'store_drop_missing_unit.dart';

part 'delivery.g.dart';

@JsonSerializable()
class Delivery {
  const Delivery({
    required this.id,
    required this.shipmentId,
    required this.vehicleId,
    required this.status,
    required this.reference,
    required this.scans,
    this.shortAddress,
    this.unitsTotal,
    this.unitIds,
    this.unitsLoaded,
    this.unitsDelivered,
    this.orderReference,
    this.customerName,
    this.address,
    this.podConfirmation,
    this.podPhotoUrl,
    this.podPhotoPath,
    this.podPhotoPaths,
    this.evidence,
    this.storeDroppedAt,
    this.storeDropNodeId,
    this.podPhotoPending,
    this.failureReason,
    this.withShortage,
    this.shortageClosedAt,
    this.shortageCloseReason,
    this.storeDropMissingUnits,
  });

  factory Delivery.fromJson(Map<String, Object?> json) =>
      _$DeliveryFromJson(json);

  @JsonKey(name: 'short_address')
  final String? shortAddress;
  @JsonKey(name: 'units_total')
  final int? unitsTotal;
  @JsonKey(name: 'unit_ids')
  final List<String>? unitIds;
  @JsonKey(name: 'units_loaded')
  final int? unitsLoaded;
  @JsonKey(name: 'units_delivered')
  final int? unitsDelivered;
  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final DeliveryStatus status;

  /// Readable label of the shipment to show the driver INSTEAD of any UUID (order reference, else customer name, else a neutral text). Never null/empty.
  final String reference;

  /// Human order code of the shipment (external_id), not a UUID.
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  final String? address;
  @JsonKey(name: 'pod_confirmation')
  final String? podConfirmation;

  /// URL para VER la foto principal de la entrega. Si la foto está en el disco privado es un enlace temporal firmado (vence solo; volver a pedir el estado para renovarlo).
  @JsonKey(name: 'pod_photo_url')
  final String? podPhotoUrl;

  /// Referencia durable de la foto en el disco de evidencia (privado)
  @JsonKey(name: 'pod_photo_path')
  final String? podPhotoPath;

  /// Referencias de las fotos ligadas a la entrega (la principal incluida).
  @JsonKey(name: 'pod_photo_paths')
  final List<String>? podPhotoPaths;

  /// Evidencia VISIBLE de la entrega, lista para mostrar: firma del cliente, foto(s) de la entrega y documento del cliente. Vacío si no hay archivos.
  final List<DeliveryEvidenceFile>? evidence;

  /// Cuándo dejó el chofer el pedido en la tienda (entrega en tienda). Null si no aplica o no pasó.
  @JsonKey(name: 'store_dropped_at')
  final DateTime? storeDroppedAt;
  @JsonKey(name: 'store_drop_node_id')
  final String? storeDropNodeId;

  /// Opción A (POD asíncrono): la entrega se cerró pero la foto todavía no subió. Se liga sola cuando llega por POST /app/deliveries/photos. La foto sigue siendo obligatoria, solo que puede llegar después.
  @JsonKey(name: 'pod_photo_pending')
  final bool? podPhotoPending;
  @JsonKey(name: 'failure_reason')
  final FailureReason? failureReason;
  final List<ScanEvent> scans;

  /// Traspaso cerrado con faltantes: entregado aunque no llegaron todos los productos (conciliación con diferencias o cierre manual de oficina).
  @JsonKey(name: 'with_shortage')
  final bool? withShortage;

  /// Cuándo se cerró con faltantes.
  @JsonKey(name: 'shortage_closed_at')
  final DateTime? shortageClosedAt;

  /// Motivo del cierre manual de oficina. Null si lo cerró la conciliación de la tienda.
  @JsonKey(name: 'shortage_close_reason')
  final String? shortageCloseReason;

  /// Productos que el chofer declaró que no pudo dejar en la tienda. Vacío si dejó el pedido completo.
  @JsonKey(name: 'store_drop_missing_units')
  final List<StoreDropMissingUnit>? storeDropMissingUnits;

  Map<String, Object?> toJson() => _$DeliveryToJson(this);
}
