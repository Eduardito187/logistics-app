import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ulid/ulid.dart';

/// Guarda la firma del cliente (PNG) en el directorio de la app para encolarla
/// como evidencia por la cola de fotos (que la copia a su propio directorio
/// persistente). Tras encolar, el archivo original se descarta.
class SignatureFileStore {
  const SignatureFileStore();

  /// Escribe [png] en `<documentos>/signatures/<ulid>.png` y devuelve la ruta.
  Future<String> save(Uint8List png) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'signatures'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    final file = File(p.join(dir.path, '${Ulid()}.png'));
    await file.writeAsBytes(png, flush: true);
    return file.path;
  }

  /// Borra el archivo (best-effort: si falla no afecta a la entrega).
  Future<void> discard(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // Se ignora: la copia encolada es la que importa.
    }
  }
}

final signatureFileStoreProvider = Provider<SignatureFileStore>(
  (ref) => const SignatureFileStore(),
);
