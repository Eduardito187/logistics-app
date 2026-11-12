import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/token_store.dart';
import 'home_widgets_prefs.dart';

/// Guarda las preferencias de widgets POR USUARIO en el almacén seguro (una
/// clave por cuenta). Lee directo del almacén (no de la precarga de
/// `TokenStore`): así un re-login en la misma ejecución ve lo último guardado.
/// Nunca falla: sin almacén quedan los valores por defecto.
class HomeWidgetsPrefsStore {
  const HomeWidgetsPrefsStore(this._storage);

  final FlutterSecureStorage _storage;

  /// Prefijo de las claves en el almacén.
  static const String keyPrefix = 'home_widgets_prefs.';

  /// Clave del usuario: el usuario del login, sin espacios y en minúsculas.
  static String userKeyOf(String userName) => userName.trim().toLowerCase();

  static String storageKeyFor(String userKey) => '$keyPrefix$userKey';

  Future<HomeWidgetsPrefs> read(String userKey) async {
    try {
      final raw = await _storage.read(key: storageKeyFor(userKey));
      return HomeWidgetsPrefs.decode(userKey, raw);
    } on Object {
      return HomeWidgetsPrefs(userKey: userKey);
    }
  }

  Future<void> write(HomeWidgetsPrefs prefs) async {
    try {
      await _storage.write(
        key: storageKeyFor(prefs.userKey),
        value: prefs.encode(),
      );
    } on Object {
      // Si no se pudo guardar, igual rige mientras la app siga abierta.
    }
  }
}

final homeWidgetsPrefsStoreProvider = Provider<HomeWidgetsPrefsStore>(
  (ref) => HomeWidgetsPrefsStore(ref.watch(secureStorageProvider)),
);
