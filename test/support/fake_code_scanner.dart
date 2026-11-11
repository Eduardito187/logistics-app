import 'package:flutter/widgets.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Escáner falso para widget tests: devuelve los [codes] en orden (un `null`
/// simula que el usuario canceló) y registra cada pedido de escaneo.
///
/// Sirve para el escaneo puntual (`codeScannerProvider.overrideWithValue(
/// fake.call)`) y para el continuo (`continuousScannerProvider.
/// overrideWithValue(fake.callContinuous)`): ambos modos comparten la misma
/// cola de códigos, así una pantalla que escanea de a uno o en ráfaga consume
/// del mismo lote que pasa el test.
class FakeCodeScanner {
  FakeCodeScanner(Iterable<String?> codes) : _codes = List.of(codes);

  final List<String?> _codes;

  /// Títulos de cada escaneo pedido, en orden (para verificar qué se pidió).
  final List<String> requestedTitles = [];

  /// Formatos de cada escaneo pedido, en orden.
  final List<List<BarcodeFormat>> requestedFormats = [];

  /// Respuestas (`ScanFeedback`) que la pantalla dio a cada código leído en modo
  /// continuo, en orden. El texto de estas respuestas (p. ej. "Firma inválida:
  /// etiqueta editada o falsa.") se muestra SOLO en el overlay del escáner real,
  /// que el fake no dibuja; por eso el test las verifica acá con
  /// [continuousMessages].
  final List<ScanFeedback> continuousFeedbacks = [];

  /// Textos de [continuousFeedbacks], en orden.
  List<String> get continuousMessages => [
    for (final f in continuousFeedbacks) f.message,
  ];

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

  /// Variante continua: cada apertura de la cámara consume UN código de la cola
  /// y lo entrega a `onCode` (como escanear un bulto y tocar "Terminar"). Si la
  /// cola está vacía o el próximo código es `null`, la sesión abre y cierra sin
  /// leer nada.
  Future<void> callContinuous(
    BuildContext context, {
    required String title,
    String? helper,
    List<BarcodeFormat>? formats,
    required ScanCodeHandler onCode,
  }) async {
    requestedTitles.add(title);
    requestedFormats.add(formats ?? const <BarcodeFormat>[]);
    if (_codes.isEmpty) return;
    final code = _codes.removeAt(0);
    if (code == null) return;
    continuousFeedbacks.add(await onCode(code));
  }
}
