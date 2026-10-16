// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/acknowledge_stock_transfer_request.dart';
import '../models/define_material_mapping_request.dart';
import '../models/enqueue_stock_transfer_request.dart';
import '../models/material_mapping_collection.dart';
import '../models/post_app_sap_material_mappings_response.dart';
import '../models/post_app_sap_stock_transfers_dispatch_response.dart';
import '../models/post_app_sap_stock_transfers_response.dart';
import '../models/post_integrations_sap_orders_import_response.dart';
import '../models/post_integrations_sap_stock_transfers_acknowledge_response.dart';
import '../models/stock_transfer_collection.dart';

part 'sap_connector_client.g.dart';

@RestApi()
abstract class SapConnectorClient {
  factory SapConnectorClient(Dio dio, {String? baseUrl}) = _SapConnectorClient;

  /// List the SAP material translation map (platform SKU to SAP coordinate)
  @GET('/app/sap/material-mappings')
  Future<MaterialMappingCollection> listMaterialMappings();

  /// Define or update a material mapping (idempotent by SKU).
  ///
  /// Define (o actualiza) el mapeo de un sku propio a su coordenada SAP (material + centro +.
  /// almacén). Idempotente por sku: redefinir un sku existente actualiza su coordenada.
  @POST('/app/sap/material-mappings')
  Future<PostAppSapMaterialMappingsResponse> defineMaterialMapping({
    @Body() required DefineMaterialMappingRequest body,
  });

  /// Enqueue a stock transfer to SAP from a node reception.
  ///
  /// Encola un traspaso de stock al recibir un bulto en un nodo. Responde 202 de inmediato: el.
  /// escaneo nunca espera a SAP. Idempotente por `event_id`.
  @POST('/app/sap/stock-transfers')
  Future<PostAppSapStockTransfersResponse> enqueueStockTransfer({
    @Body() required EnqueueStockTransferRequest body,
  });

  /// Trigger a dispatch run for pending and failed stock transfers
  @POST('/app/sap/stock-transfers/dispatch')
  Future<PostAppSapStockTransfersDispatchResponse>
  dispatchPendingStockTransfers();

  /// List stock transfers whose dispatch to SAP failed
  @GET('/app/sap/stock-transfers/failed')
  Future<StockTransferCollection> listFailedStockTransfers();

  /// List stock transfers pending dispatch to SAP (Pending and Failed)
  @GET('/app/sap/stock-transfers/pending')
  Future<StockTransferCollection> listPendingStockTransfers();

  /// Import pending orders from SAP, translated to the platform model.
  ///
  /// Lee los pedidos pendientes en SAP y los devuelve ya traducidos al modelo propio (sku propio,.
  /// no material SAP). No empuja nada a SAP dentro del request.
  @POST('/integrations/sap/orders/import')
  Future<PostIntegrationsSapOrdersImportResponse> importSapOrders();

  /// Acknowledge a dispatched stock transfer (SAP callback).
  ///
  /// Callback de SAP que confirma un traspaso ya empujado. Cierra el ciclo y lo saca del panel de.
  /// reconciliación. Idempotente por `event_id`: reconfirmar no es un error.
  @POST('/integrations/sap/stock-transfers/acknowledge')
  Future<PostIntegrationsSapStockTransfersAcknowledgeResponse>
  acknowledgeStockTransfer({
    @Body() required AcknowledgeStockTransferRequest body,
  });
}
