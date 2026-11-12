import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/app_database.dart';
import '../../domain/models/carrier_scan_kind.dart';
import '../../domain/models/queued_carrier_scan.dart';

/// Lectura de la cola offline del dispositivo para rearmar la tanda de escaneo
/// del transportista al reabrir la pantalla.
///
/// Solo LEE: la cola la escribe `OfflineQueue` (core) y acá no se agrega
/// persistencia nueva. Se consulta directo porque hace falta el `payload` (el
/// `unit_id` del producto) de unas pocas filas propias: `watchQueue` no trae el
/// payload y `pendingActions` traería TODA la cola (días de posiciones GPS
/// incluidas) en un teléfono de 512 MB.
class CarrierScanQueueSource {
  const CarrierScanQueueSource(this._db);

  final AppDatabase _db;

  /// Estado de las filas que todavía no subieron (ver `OutboxActions.status`).
  /// Las sincronizadas se BORRAN de la cola y las `failed` no se reconstruyen.
  static const String _pendingStatus = 'pending';

  /// Tope de filas leídas, igual al tope de la lista de la pantalla
  /// (`kMaxSessionRecords`): más allá de eso no se muestran igual.
  static const int maxRows = 200;

  /// Escaneos [kind] del transportista que siguen en la cola, el último
  /// primero. Nunca lanza por una fila rara: la saltea.
  Future<List<QueuedCarrierScan>> pending(CarrierScanKind kind) async {
    final query = _db.select(_db.outboxActions)
      ..where(
        (t) =>
            t.kind.equals(kind.queueKind) &
            t.status.equals(_pendingStatus) &
            // El prefijo propio del transportista (el resto lo valida `skuOf`):
            // el chofer y la tienda encolan con el MISMO `kind`.
            t.label.like('${kind.labelPrefix}%'),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(maxRows);
    final rows = await query.get();
    final scans = <QueuedCarrierScan>[];
    for (final row in rows) {
      final sku = kind.skuOf(row.label);
      if (sku == null) continue;
      final unitId = _unitIdOf(row.payload);
      if (unitId == null) continue;
      scans.add(
        QueuedCarrierScan(unitId: unitId, sku: sku, at: row.occurredAt),
      );
    }
    return scans;
  }

  /// `unit_id` del payload encolado (`ScanRequest`/`ProofOfDeliveryRequest`),
  /// o `null` si el JSON no se puede leer (fila de otra versión o corrupta).
  String? _unitIdOf(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, Object?>) return null;
      final unitId = json['unit_id'];
      return unitId is String && unitId.isNotEmpty ? unitId : null;
    } on FormatException {
      return null;
    }
  }
}

final carrierScanQueueSourceProvider = Provider<CarrierScanQueueSource>(
  (ref) => CarrierScanQueueSource(ref.watch(appDatabaseProvider)),
);
