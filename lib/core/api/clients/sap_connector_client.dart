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
import '../models/post_integrations_sap_stock_transfers_acknowledge_response.dart';
import '../models/sap_async_request_accepted.dart';
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
  /// Encola un traspaso de stock al recibir un producto en un nodo. Responde 202 de inmediato: el.
  /// escaneo nunca espera a SAP. Idempotente por `event_id`.
  @POST('/app/sap/stock-transfers')
  Future<PostAppSapStockTransfersResponse> enqueueStockTransfer({
    @Body() required EnqueueStockTransferRequest body,
  });

  /// Queue a reconciliation run for failed and stale pending stock transfers.
  ///
  /// Encola (cola `sap`) una corrida de reconciliación y responde de inmediato con 202: SAP nunca se.
  /// llama dentro del request. La corrida reintenta los traspasos Failed y los Pending estancados.
  /// (más viejos que `transfers.stale_pending_minutes`); los traspasos nuevos los empuja solo el.
  /// reactor del outbox, para no duplicar el envío.
  @POST('/app/sap/stock-transfers/dispatch')
  Future<PostAppSapStockTransfersDispatchResponse>
  dispatchPendingStockTransfers();

  /// List stock transfers whose dispatch to SAP failed
  @GET('/app/sap/stock-transfers/failed')
  Future<StockTransferCollection> listFailedStockTransfers();

  /// List stock transfers pending dispatch to SAP (Pending and Failed)
  @GET('/app/sap/stock-transfers/pending')
  Future<StockTransferCollection> listPendingStockTransfers();

  /// Request an asynchronous import of pending orders from SAP.
  ///
  /// Encola la lectura de pedidos pendientes en SAP (job en la cola `sap`) y responde de inmediato.
  /// con 202. SAP NUNCA se llama dentro del request: su lentitud o caída no afecta a la plataforma.
  /// El worker traduce los pedidos al modelo propio (sku propio, no material SAP).
  @POST('/integrations/sap/orders/import')
  Future<SapAsyncRequestAccepted> importSapOrders();

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
