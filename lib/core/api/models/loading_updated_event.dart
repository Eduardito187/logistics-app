// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'loading_updated_event.g.dart';

/// Señal `loading.updated` (tema loading): cambió la carga del camión o su lista de entregas (escaneo de carga, asignar/desenganchar un envío, armar/editar la ruta). Canales `private-loading.all` / `private-loading.city.<departamento>` / `private-loading.driver.<uuid>`. shipment_id null = la lista del vehículo cambió en general.
@JsonSerializable()
class LoadingUpdatedEvent {
  const LoadingUpdatedEvent({required this.vehicleId, this.shipmentId});

  factory LoadingUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$LoadingUpdatedEventFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;

  Map<String, Object?> toJson() => _$LoadingUpdatedEventToJson(this);
}
