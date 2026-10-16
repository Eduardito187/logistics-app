import 'package:drift/drift.dart';

/// Cola local de FOTOS de evidencia (POD / daños) pendientes de subir.
///
/// Offline-first (CLAUDE.md regla #4): la foto se copia a un directorio
/// persistente de la app y se encola con un `id` idempotente (ULID). La subida
/// multipart (`uploadDeliveryPhoto`) se reintenta al recuperar señal; al subir
/// bien se borra la fila y el archivo local.
class PendingPhotos extends Table {
  /// ULID generado en terreno; también sirve de clave local idempotente.
  TextColumn get id => text()();

  /// Envío al que pertenece la evidencia.
  TextColumn get shipmentId => text()();

  /// Ruta local persistente de la foto (sobrevive a que el picker borre el
  /// archivo de caché).
  TextColumn get filePath => text()();

  /// `pod` (prueba de entrega) | `damage` (daños).
  TextColumn get kind => text().withDefault(const Constant('pod'))();

  /// `pending` | `failed`. Las subidas OK se borran.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
