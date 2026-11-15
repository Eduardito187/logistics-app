// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment_progress_execution_status.dart';

part 'shipment_progress.g.dart';

/// Operational progress of the shipment (read-side enrichment, only on GET /app/shipments). Fields are null when unknown.
@JsonSerializable()
class ShipmentProgress {
  const ShipmentProgress({
    required this.vehicleId,
    required this.plate,
    required this.assignedAt,
    required this.preparedAt,
    required this.loadedAt,
    required this.deliveredAt,
    required this.labelsEmittedCount,
    required this.executionStatus,
    this.readyForPickupAt,
  });

  factory ShipmentProgress.fromJson(Map<String, Object?> json) =>
      _$ShipmentProgressFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  final String? plate;
  @JsonKey(name: 'assigned_at')
  final DateTime? assignedAt;
  @JsonKey(name: 'prepared_at')
  final DateTime? preparedAt;
  @JsonKey(name: 'loaded_at')
  final DateTime? loadedAt;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;

  /// Labels emitted for the order (per order_reference; multishipping siblings share it).
  @JsonKey(name: 'labels_emitted_count')
  final int? labelsEmittedCount;

  /// Cuándo quedó el pedido en su tienda destino listo para que el cliente lo retire (recepción conciliada en esa tienda). Null si todavía no llegó.
  @JsonKey(name: 'ready_for_pickup_at')
  final DateTime? readyForPickupAt;
  @JsonKey(name: 'execution_status')
  final ShipmentProgressExecutionStatus? executionStatus;

  Map<String, Object?> toJson() => _$ShipmentProgressToJson(this);
}
