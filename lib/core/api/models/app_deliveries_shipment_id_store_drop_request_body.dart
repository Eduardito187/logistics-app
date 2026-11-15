// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'store_drop_missing_unit.dart';

part 'app_deliveries_shipment_id_store_drop_request_body.g.dart';

@JsonSerializable()
class AppDeliveriesShipmentIdStoreDropRequestBody {
  const AppDeliveriesShipmentIdStoreDropRequestBody({
    this.nodeId,
    this.photoPath,
    this.occurredAt,
    this.lat,
    this.lng,
    this.missingUnits,
  });

  factory AppDeliveriesShipmentIdStoreDropRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppDeliveriesShipmentIdStoreDropRequestBodyFromJson(json);

  /// Tienda donde se deja el pedido. Si se omite se usa la tienda destino del envío; si se manda debe ser esa.
  @JsonKey(name: 'node_id')
  final String? nodeId;

  /// Referencia devuelta por POST /app/deliveries/photos (kind pod). Opcional.
  @JsonKey(name: 'photo_path')
  final String? photoPath;

  /// Momento de la entrega en tienda. Si se omite, la hora del servidor.
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;
  final num? lat;
  final num? lng;

  /// Productos que el chofer NO pudo dejar en la tienda. Opcional: sin la lista, dejó el pedido completo. 422 si un producto no es del pedido o si se declara el pedido entero.
  @JsonKey(name: 'missing_units')
  final List<StoreDropMissingUnit>? missingUnits;

  Map<String, Object?> toJson() =>
      _$AppDeliveriesShipmentIdStoreDropRequestBodyToJson(this);
}
