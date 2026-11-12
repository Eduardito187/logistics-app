import '../../../../core/api/models/dispatch_lines_response.dart';
import '../../../../core/api/models/emit_labels_request.dart';
import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/api/models/preparation_scan_request.dart';
import '../entities/shipment_page.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../../../core/offline/offline_queue.dart';

/// Contrato del repositorio de preparación (preparador / andén). Agrupa las
/// operaciones del feature tipadas con los modelos del contrato OpenAPI. La
/// implementación vive en `data/`; `presentation` sólo lo conoce vía casos de uso.
///
/// Las lecturas y las escrituras con red propagan [ApiException] ante un error;
/// el registro de escaneo es offline-first y devuelve el [SubmitOutcome] de la cola.
abstract interface class PickingRepository {
  /// Pedidos del backend filtrados en el servidor por [status], paginados por
  /// CURSOR. El conjunto "por preparar/cargar" lo arma el caso de uso
  /// [ListOrdersToPrepare] (un pedido por estado, en paralelo).
  Future<ShipmentPage> listShipments({
    ShipmentStatus? status,
    int page,
    int perPage,
  });

  /// Etiquetas (productos) ya emitidas del pedido.
  Future<List<EmittedLabel>> getOrderLabels(String orderNumber);
  Future<DispatchLinesResponse> getOrderDispatchLines(String orderNumber);

  /// Emite las etiquetas del pedido POR ORDEN: el backend deriva origen/destino
  /// y líneas del plan publicado y emite las autorizadas y pendientes. Sin form.
  /// Idempotente (reabrir emite lo que falte). Devuelve la colección completa.
  Future<List<EmittedLabel>> emitOrderLabels(String orderNumber);

  /// Emite un lote de etiquetas con origen/destino/líneas explícitos (legado /
  /// reimpresión). La emisión normal usa [emitOrderLabels].
  Future<List<EmittedLabel>> emitLabels(
    String orderNumber,
    EmitLabelsRequest body,
  );

  /// Ata el pedido al vehículo EN EL BACKEND (queda como parada de su ruta).
  /// Sin esto la asignación es solo local y el pedido sigue en "por preparar".
  Future<void> assignVehicle(String orderNumber, String vehicleId);

  /// ZPL firmado por el backend (todas las etiquetas concatenadas).
  Future<String> getSignedZpl(String orderNumber);

  /// Registra la preparación de una unidad. Escritura de terreno offline-first:
  /// pasa por la cola (`offlineQueueProvider.submit`) con ID idempotente.
  Future<SubmitOutcome> recordPreparationScan(PreparationScanRequest scan);
}
