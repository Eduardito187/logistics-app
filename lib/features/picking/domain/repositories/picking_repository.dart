import '../../../../core/api/models/emit_labels_request.dart';
import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/api/models/preparation_scan_request.dart';
import '../../../../core/api/models/reprint_labels_request.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/offline/offline_queue.dart';

/// Contrato del repositorio de preparación (preparador / andén). Agrupa las
/// operaciones del feature tipadas con los modelos del contrato OpenAPI. La
/// implementación vive en `data/`; `presentation` sólo lo conoce vía casos de uso.
///
/// Las lecturas y las escrituras con red propagan [ApiException] ante un error;
/// el registro de escaneo es offline-first y devuelve el [SubmitOutcome] de la cola.
abstract interface class PickingRepository {
  /// Pedidos recibidos del backend (sin filtrar). El filtrado por estado
  /// "por preparar/cargar" lo hace el caso de uso [ListOrdersToPrepare].
  Future<List<Shipment>> listShipments();

  /// Etiquetas (unidades/bultos) ya emitidas del pedido.
  Future<List<EmittedLabel>> getOrderLabels(String orderNumber);

  /// Emite el lote de etiquetas del pedido y devuelve las creadas.
  Future<List<EmittedLabel>> emitLabels(
    String orderNumber,
    EmitLabelsRequest body,
  );

  /// Revoca las etiquetas vigentes y emite un lote nuevo (motivo obligatorio).
  Future<List<EmittedLabel>> reprintLabels(
    String orderNumber,
    ReprintLabelsRequest body,
  );

  /// ZPL firmado por el backend (todas las etiquetas concatenadas).
  Future<String> getSignedZpl(String orderNumber);

  /// Registra la preparación de una unidad. Escritura de terreno offline-first:
  /// pasa por la cola (`offlineQueueProvider.submit`) con ID idempotente.
  Future<SubmitOutcome> recordPreparationScan(PreparationScanRequest scan);
}
