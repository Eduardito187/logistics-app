import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/emit_labels_request.dart';
import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/api/models/preparation_scan_request.dart';
import '../../../../core/api/models/reprint_labels_request.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../domain/repositories/picking_repository.dart';
import '../datasources/picking_remote_data_source.dart';

/// Implementación del contrato de preparación. Las operaciones sobre etiquetas
/// delegan en la fuente de datos remota; el registro de escaneo es offline-first
/// y pasa por la cola (persiste local con ID idempotente y sincroniza después).
class PickingRepositoryImpl implements PickingRepository {
  const PickingRepositoryImpl(this._remote, this._queue);

  final PickingRemoteDataSource _remote;
  final OfflineQueue _queue;

  @override
  Future<List<Shipment>> listShipments({ShipmentStatus? status}) =>
      _remote.listShipments(status: status);

  @override
  Future<List<EmittedLabel>> getOrderLabels(String orderNumber) =>
      _remote.getOrderLabels(orderNumber);

  @override
  Future<List<EmittedLabel>> emitLabels(
    String orderNumber,
    EmitLabelsRequest body,
  ) => _remote.emitLabels(orderNumber, body);

  @override
  Future<List<EmittedLabel>> reprintLabels(
    String orderNumber,
    ReprintLabelsRequest body,
  ) => _remote.reprintLabels(orderNumber, body);

  @override
  Future<String> getSignedZpl(String orderNumber) =>
      _remote.getSignedZpl(orderNumber);

  @override
  Future<SubmitOutcome> recordPreparationScan(PreparationScanRequest scan) {
    // Un escaneo nunca espera a la red: se encola con ID idempotente y se
    // sincroniza al reconectar (`recordPreparationScan` en `offlineHandlers`).
    return _queue.submit(
      kind: 'recordPreparationScan',
      payload: scan.toJson(),
      label: 'Preparación · pedido ${scan.shipmentId}',
      occurredAt: scan.occurredAt,
    );
  }
}

/// Proveedor del repositorio de preparación (devuelve el tipo interfaz).
final pickingRepositoryProvider = Provider<PickingRepository>(
  (ref) => PickingRepositoryImpl(
    ref.watch(pickingRemoteDataSourceProvider),
    ref.watch(offlineQueueProvider),
  ),
);
