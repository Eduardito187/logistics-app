// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/available_to_promise_envelope.dart';
import '../models/fulfillment_mode.dart';
import '../models/lot_collection.dart';
import '../models/stock_on_hand_collection.dart';

part 'inventory_client.g.dart';

@RestApi()
abstract class InventoryClient {
  factory InventoryClient(Dio dio, {String? baseUrl}) = _InventoryClient;

  /// Stock on-hand by owner.
  ///
  /// Stock on-hand de un almacén/sku agregado por dueño (propio de Dismac vs. consignación de cada seller).
  @GET('/integrations/inventory/on-hand')
  Future<StockOnHandCollection> getStockOnHand({
    @Query('warehouse_id') required String warehouseId,
    @Query('sku') required String sku,
    @Query('owner_party_id') String? ownerPartyId,
    @Query('fulfillment_mode') FulfillmentMode? fulfillmentMode,
  });

  /// Available-to-Promise for a warehouse/sku.
  ///
  /// Stock disponible, no reservado, que el motor de promesa puede comprometer para un almacén/sku,.
  /// opcionalmente por dueño.
  @GET('/integrations/inventory/available-to-promise')
  Future<AvailableToPromiseEnvelope> getAvailableToPromise({
    @Query('warehouse_id') required String warehouseId,
    @Query('sku') required String sku,
    @Query('owner_party_id') String? ownerPartyId,
  });

  /// List stock lots
  @GET('/integrations/inventory/lots')
  Future<LotCollection> listLots({
    @Query('limit') int? limit = 100,
    @Query('offset') int? offset = 0,
    @Query('warehouse_id') String? warehouseId,
    @Query('sku') String? sku,
    @Query('owner_party_id') String? ownerPartyId,
    @Query('fulfillment_mode') FulfillmentMode? fulfillmentMode,
  });
}
