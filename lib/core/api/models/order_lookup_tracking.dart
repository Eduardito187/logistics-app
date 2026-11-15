// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_lookup_node_ref.dart';
import 'order_lookup_stage.dart';

part 'order_lookup_tracking.g.dart';

@JsonSerializable()
class OrderLookupTracking {
  const OrderLookupTracking({
    required this.stage,
    required this.stopsBefore,
    required this.etaAt,
    required this.vehiclePlate,
    required this.currentNode,
  });

  factory OrderLookupTracking.fromJson(Map<String, Object?> json) =>
      _$OrderLookupTrackingFromJson(json);

  final OrderLookupStage stage;

  /// Paradas pendientes que tiene el camión ANTES de este envío. Null si el envío no está en una ruta o la etapa es at_store, delivered, failed o cancelled.
  @JsonKey(name: 'stops_before')
  final int? stopsBefore;
  @JsonKey(name: 'eta_at')
  final DateTime? etaAt;
  @JsonKey(name: 'vehicle_plate')
  final String? vehiclePlate;

  /// Nodo donde está el pedido ahora; es la tienda destino cuando la etapa es at_store.
  @JsonKey(name: 'current_node')
  final OrderLookupNodeRef? currentNode;

  Map<String, Object?> toJson() => _$OrderLookupTrackingToJson(this);
}
