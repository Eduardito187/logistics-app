import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:logistics_app/core/scanning/continuous_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Escáner continuo falso: en cada sesión entrega los códigos guionizados de
/// [sessions] (una lista por apertura de la cámara) a `onCode`, en orden, y
/// guarda cada [ScanFeedback] devuelto. Una sesión sin códigos simula abrir y
/// tocar "Terminar" sin leer nada.
///
/// Uso: `continuousScannerProvider.overrideWithValue(fake.call)`.
class FakeContinuousScanner {
  FakeContinuousScanner(List<List<String>> sessions)
    : _sessions = [for (final s in sessions) List.of(s)];

  /// Una sola sesión con [codes].
  FakeContinuousScanner.single(List<String> codes) : this([codes]);

  final List<List<String>> _sessions;

  /// Títulos de cada sesión abierta.
  final List<String> titles = [];

  /// Formatos pedidos en cada sesión.
  final List<List<BarcodeFormat>?> formats = [];

  /// Avisos devueltos por la pantalla, en orden (todas las sesiones).
  final List<ScanFeedback> feedbacks = [];

  /// Textos de [feedbacks].
  List<String> get messages => [for (final f in feedbacks) f.message];

  Future<void> call(
    BuildContext context, {
    required String title,
    String? helper,
    List<BarcodeFormat>? formats,
    required ScanCodeHandler onCode,
  }) async {
    titles.add(title);
    this.formats.add(formats);
    final codes = _sessions.isEmpty ? const <String>[] : _sessions.removeAt(0);
    for (final code in codes) {
      feedbacks.add(await onCode(code));
    }
  }
}

/// QR de etiqueta con formato válido y firma de relleno (no verifica): sirve
/// para sesiones con varios bultos distintos usando un scanner SIN claves.
String unsignedLabelQr(String unitId, {String order = 'DM-1'}) => jsonEncode({
  'v': 1,
  't': 'PKG',
  'k': 1,
  'id': unitId,
  'o': order,
  'ln': 1,
  'sku': 'SKU-1',
  'u': [1, 1],
  'pc': [1, 1],
  'org': 'CD-SCZ',
  'dst': 'C',
  'ts': 1759312800,
  's': base64Url.encode(List.filled(64, 7)).replaceAll('=', ''),
});
