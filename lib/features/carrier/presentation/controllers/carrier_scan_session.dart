import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/submit_outcome.dart';
import '../../data/datasources/carrier_scan_queue_source.dart';
import '../../domain/models/carrier_scan_kind.dart';
import '../../domain/models/queued_carrier_scan.dart';
import '../widgets/carrier_scan_record.dart';

/// Tanda de escaneo del transportista (recoger o entregar): el historial que ve
/// el usuario y, con él, qué productos ya están registrados.
///
/// Vive FUERA de la pantalla (ver el provider) para que salir y volver no borre
/// lo escaneado: la cola offline sube los registros igual, pero el usuario veía
/// la lista vacía y sin el "ya recogido / ya entregado" podía volver a escanear
/// lo mismo.
///
/// Al abrir la pantalla se RECONSTRUYE desde la cola offline
/// ([CarrierScanQueueSource]), que es la única fuente disponible (el backend no
/// expone "lo que este transportista escaneó hoy"). Lo que queda AFUERA, y por
/// qué:
///
/// - Lo YA SINCRONIZADO: `OfflineQueue.markSynced` BORRA la fila de la cola, así
///   que después de cerrar la app no hay de dónde recuperarlo. Dentro de la
///   misma corrida de la app se ve todo (lo guarda este notifier); tras
///   reiniciar, vuelve solo lo que todavía no subió. No se inventa persistencia
///   nueva en `core` para cubrirlo.
/// - Las filas `failed` (rechazo del backend): no se reconstruyen; el "Error"
///   se ve solo en la tanda en curso, y volver a escanear ese producto está
///   permitido igual (es lo que corresponde tras un rechazo).
/// - El resultado del envío de lo reconstruido se muestra como encolado
///   ([SubmitOutcome.queued] → "Enviado"): la fila sigue en la cola, y el
///   offline es invisible para el usuario.
class CarrierScanSession extends Notifier<List<CarrierScanRecord>> {
  CarrierScanSession(this.kind);

  /// Qué escaneo es esta tanda (define el `kind` y el prefijo en la cola).
  final CarrierScanKind kind;

  /// La reconstrucción se hace UNA vez por tanda: después el estado en memoria
  /// es la verdad (incluye lo que ya se sincronizó y salió de la cola).
  bool _restored = false;

  @override
  List<CarrierScanRecord> build() => const [];

  /// Rearma el historial con lo que quedó en la cola offline. Idempotente y
  /// nunca lanza: si la base local falla, la pantalla simplemente arranca con
  /// lo que tenga en memoria (y se puede reintentar al reabrirla).
  Future<void> restoreFromQueue() async {
    if (_restored) return;
    _restored = true;
    final List<QueuedCarrierScan> queued;
    try {
      queued = await ref.read(carrierScanQueueSourceProvider).pending(kind);
    } on Object {
      _restored = false;
      return;
    }
    if (queued.isEmpty) return;
    // Lo que ya está en memoria manda (es de esta corrida, con su resultado
    // real); de la cola solo entra lo que falta.
    final known = {for (final record in state) record.unitId};
    final restored = [
      for (final scan in queued)
        if (!known.contains(scan.unitId))
          CarrierScanRecord(
            unitId: scan.unitId,
            title: scan.sku,
            outcome: SubmitOutcome.queued,
            at: scan.at,
          ),
    ];
    if (restored.isEmpty) return;
    // Lo último arriba, igual que [addSessionRecord], y acotado al mismo tope.
    final next = [...state, ...restored]..sort((a, b) => b.at.compareTo(a.at));
    state = List.unmodifiable(next.take(kMaxSessionRecords));
  }

  /// ¿Este producto ya quedó registrado en la tanda? Un rechazo del backend no
  /// cuenta: ese producto se puede volver a escanear.
  bool isRegistered(String unitId) => state.any(
    (record) =>
        record.unitId == unitId && record.outcome != SubmitOutcome.failed,
  );

  /// Agrega el resultado de una lectura al historial (lo último arriba).
  void add(CarrierScanRecord record) {
    final next = [...state];
    addSessionRecord(next, record);
    state = List.unmodifiable(next);
  }
}

/// SIN `autoDispose` a propósito (igual que `preparationControllerProvider`):
/// el historial de la tanda tiene que sobrevivir a salir y volver a la
/// pantalla. Es chico: a lo sumo [kMaxSessionRecords] filas por tipo de
/// escaneo (dos: recoger y entregar).
final carrierScanSessionProvider =
    NotifierProvider.family<
      CarrierScanSession,
      List<CarrierScanRecord>,
      CarrierScanKind
    >(CarrierScanSession.new);
