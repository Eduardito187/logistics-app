import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/auth/token_store.dart';

/// Recuerda el ÚLTIMO camión que se le asignó al chofer (una clave por usuario),
/// en el almacén seguro.
///
/// Es la red de seguridad del lado app para que NUNCA se le pierda al chofer una
/// ruta EN CURSO: si `my-crew` no devuelve asignación (p. ej. una entrega que
/// cruzó la medianoche, que lleva días abierta por un envío largo, un bloqueo o
/// un problema de ruta, o un parpadeo del backend), la app usa este camión para
/// pedir su RUTA ABIERTA (que el backend resuelve de cualquier día) y seguir
/// mostrándola. Nunca falla: sin almacén simplemente no hay respaldo.
class LastVehicleStore {
  const LastVehicleStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _keyPrefix = 'driver_last_vehicle_id.';

  /// Clave por usuario del login (sin espacios, en minúsculas), como el resto de
  /// los almacenes por cuenta.
  static String _keyFor(String userName) =>
      '$_keyPrefix${userName.trim().toLowerCase()}';

  Future<String?> read(String userName) async {
    try {
      final value = await _storage.read(key: _keyFor(userName));
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    } on Object {
      return null;
    }
  }

  Future<void> write(String userName, String vehicleId) async {
    final id = vehicleId.trim();
    if (id.isEmpty) return;
    try {
      await _storage.write(key: _keyFor(userName), value: id);
    } on Object {
      // Si no se pudo guardar, el respaldo simplemente no estará la próxima vez.
    }
  }
}

final lastVehicleStoreProvider = Provider<LastVehicleStore>(
  (ref) => LastVehicleStore(ref.watch(secureStorageProvider)),
);
