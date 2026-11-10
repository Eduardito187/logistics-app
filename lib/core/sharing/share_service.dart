import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Comparte imágenes y archivos por el menú de compartir NATIVO del móvil
/// (WhatsApp, correo, Drive, lo que sea): etiquetas, firmas del cliente y fotos
/// de evidencia. Es un "seam" para los tests: en pruebas se inyecta un doble
/// con [shareServiceProvider] y no se abre el menú real del sistema.
abstract class ShareService {
  /// Comparte bytes de una imagen PNG (etiqueta renderizada, firma). Escribe un
  /// archivo temporal con [filename] y abre el menú nativo; [text] acompaña el
  /// envío (p. ej. "Etiqueta · Pedido SCZ-123").
  Future<void> shareImagePng(
    Uint8List bytes, {
    required String filename,
    String? text,
  });

  /// Comparte un archivo que ya está en disco (foto de evidencia/documento).
  Future<void> shareFile(String path, {String? text});
}

/// Implementación real sobre `share_plus`. Se sustituye en tests.
final shareServiceProvider = Provider<ShareService>(
  (ref) => const PlatformShareService(),
);

/// Comparte usando el menú del sistema operativo (`share_plus`).
class PlatformShareService implements ShareService {
  const PlatformShareService();

  @override
  Future<void> shareImagePng(
    Uint8List bytes, {
    required String filename,
    String? text,
  }) async {
    // El menú nativo comparte ARCHIVOS: se vuelca el PNG a un temporal (se
    // sobrescribe en cada compartir; no hace falta limpiarlo a mano).
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'image/png', name: filename),
    ], text: text);
  }

  @override
  Future<void> shareFile(String path, {String? text}) async {
    await Share.shareXFiles([XFile(path)], text: text);
  }
}
