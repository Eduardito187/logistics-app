import 'package:drift/drift.dart';

/// Cola local de acciones de escritura (patrón outbox en el dispositivo).
///
/// Offline-first (CLAUDE.md regla #4): un escaneo nunca espera a la red. Se
/// guarda acá con un `id` idempotente (ULID) y se sincroniza después. El mismo
/// `id` viaja como `Idempotency-Key`, así que un reenvío no duplica el hecho.
class OutboxActions extends Table {
  /// ULID generado en terreno; también es la clave de idempotencia del backend.
  TextColumn get id => text()();

  /// Tipo de acción (p. ej. `recordLoadScan`); el dispatcher la mapea a un
  /// endpoint del cliente generado.
  TextColumn get kind => text()();

  /// Cuerpo de la request serializado a JSON.
  TextColumn get payload => text()();

  /// Momento real del hecho en terreno (lo fija la app, no el servidor).
  DateTimeColumn get occurredAt => dateTime()();

  /// `pending` | `syncing` | `failed`. Las sincronizadas se borran.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Etiqueta legible para la UI de sincronización (p. ej. "Carga · pedido 123").
  TextColumn get label => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
