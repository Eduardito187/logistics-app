import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Escáner falso para widget tests: devuelve los [codes] en orden (un `null`
/// simula que el usuario canceló) y registra cada pedido de escaneo.
///
/// Uso: `codeScannerProvider.overrideWithValue(fake.call)`.
class FakeCodeScanner {
  FakeCodeScanner(Iterable<String?> codes) : _codes = List.of(codes);

  final List<String?> _codes;

  /// Títulos de cada escaneo pedido, en orden (para verificar qué se pidió).
  final List<String> requestedTitles = [];

  /// Formatos de cada escaneo pedido, en orden.
  final List<List<BarcodeFormat>> requestedFormats = [];

  Future<String?> call(
    BuildContext context, {
    required String title,
    String? helper,
    required List<BarcodeFormat> formats,
  }) async {
    requestedTitles.add(title);
    requestedFormats.add(formats);
    return _codes.isEmpty ? null : _codes.removeAt(0);
  }
}
