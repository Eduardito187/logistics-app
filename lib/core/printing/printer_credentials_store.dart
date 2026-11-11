import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/token_store.dart';
import 'printer_credentials.dart';

/// Credenciales por impresora en el almacén seguro (Keystore/Keychain, cifrado
/// por el sistema). Clave por dirección (`ip:puerto`) para que cambiar de
/// impresora no mezcle usuarios.
class PrinterCredentialsStore {
  const PrinterCredentialsStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _prefix = 'printer_credentials_';

  static String keyFor(String address) => '$_prefix${address.trim()}';

  /// Credenciales guardadas para [address], o `null`. Nunca lanza.
  Future<PrinterCredentials?> read(String address) async {
    try {
      return PrinterCredentials.decode(
        await _storage.read(key: keyFor(address)),
      );
    } on Object {
      return null;
    }
  }

  /// Guarda (o borra, si el usuario quedó vacío) las de [address].
  Future<void> write(String address, PrinterCredentials? credentials) async {
    if (credentials == null || credentials.username.trim().isEmpty) {
      await _storage.delete(key: keyFor(address));
      return;
    }
    await _storage.write(key: keyFor(address), value: credentials.encode());
  }

  Future<void> delete(String address) => _storage.delete(key: keyFor(address));
}

final printerCredentialsStoreProvider = Provider<PrinterCredentialsStore>(
  (ref) => PrinterCredentialsStore(ref.watch(secureStorageProvider)),
);
