import 'package:flutter/widgets.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Escáner CONTINUO falso para widget tests de store/picking/carrier: cada
/// apertura de la cámara consume una sesión de [sessions] y llama a `onCode`
/// con sus códigos en orden (como si se leyeran uno tras otro sin cerrar la
/// cámara). Una sesión vacía = se abrió y se tocó "Terminar" sin leer nada.
///
/// No replica el filtro anti-repetición (< 2 s) del core: un código repetido
/// llega al handler, como cuando se vuelve a apuntar pasada la ventana.
///
/// Uso: `continuousScannerProvider.overrideWithValue(fake.call)`.
class FakeContinuousScanner {
  /// Una sola sesión con [codes].
  FakeContinuousScanner(Iterable<String> codes) : this.sessions([codes]);

  /// Varias aperturas de la cámara, una por elemento.
  FakeContinuousScanner.sessions(Iterable<Iterable<String>> sessions)
    : _sessions = [for (final s in sessions) List.of(s)];

  final List<List<String>> _sessions;

  /// Títulos de cada apertura, en orden.
  final List<String> requestedTitles = [];

  /// Formatos de cada apertura, en orden.
  final List<List<BarcodeFormat>?> requestedFormats = [];

  /// Respuesta de la pantalla a cada código leído, en orden.
  final List<ScanFeedback> feedbacks = [];

  /// Textos de [feedbacks].
  List<String> get messages => [for (final f in feedbacks) f.message];

  /// Cuántos códigos se aceptaron (verde).
  int get okCount => feedbacks.where((f) => f.ok).length;

  Future<void> call(
    BuildContext context, {
    required String title,
    String? helper,
    List<BarcodeFormat>? formats,
    required ScanCodeHandler onCode,
  }) async {
    requestedTitles.add(title);
    requestedFormats.add(formats);
    final codes = _sessions.isEmpty ? const <String>[] : _sessions.removeAt(0);
    for (final code in codes) {
      feedbacks.add(await onCode(code));
    }
  }
}
