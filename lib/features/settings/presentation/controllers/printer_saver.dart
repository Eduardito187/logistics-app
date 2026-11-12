import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/token_store.dart';
import '../../../../core/printing/label_printer.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/printing/printer_credentials_store.dart';
import '../../../../core/printing/printer_detection.dart';
import '../../../../core/printing/printer_profile_detector.dart';
import '../../../../core/widgets/app_snack.dart';
import 'printer_controllers.dart';
import 'printer_save_result.dart';

/// Guardado de la impresora activa, compartido por el asistente "Conectar
/// impresora" y las opciones avanzadas de la tarjeta.
///
/// - Elegir una impresora: si es la MISMA WiFi que la activa se conserva su
///   perfil (tipo/protocolo); si es otra WiFi, el que llama debe detectar su
///   tipo después ([detect]).
/// - Detectar: IPP/web, NUNCA manda bytes al 9100.
/// - Olvidar: borra la activa y sus credenciales.
class PrinterSaver {
  PrinterSaver(this._ref);

  final WidgetRef _ref;

  /// La activa según el provider; si no se pudo leer, `null` (se guarda igual).
  Future<PrinterConfig?> current() async {
    try {
      return await _ref.read(selectedPrinterProvider.future);
    } on Object {
      return null;
    }
  }

  /// Guarda [config] como impresora activa. [isNewWifi] = hay que detectar
  /// su tipo; [config] es lo que quedó guardado (con el perfil conservado).
  Future<({PrinterSaveResult result, PrinterConfig config, bool isNewWifi})>
  choose(PrinterConfig config) async {
    final active = await current();
    var toSave = config;
    var sameWifi = false;
    if (active != null &&
        config.transport == PrinterTransport.wifi &&
        active.transport == PrinterTransport.wifi &&
        active.address == config.address) {
      // Re-elegida desde la búsqueda o el form (que traen el perfil por
      // defecto): se conserva el perfil que ya tenía.
      sameWifi = true;
      toSave = config.copyWith(
        language: active.language,
        protocol: active.protocol,
        ippPath: active.ippPath,
        ippPort: active.ippPort,
        ippTls: active.ippTls,
      );
    }
    final result = await persist(toSave);
    return (
      result: result,
      config: toSave,
      isNewWifi:
          result == PrinterSaveResult.saved &&
          toSave.transport == PrinterTransport.wifi &&
          !sameWifi,
    );
  }

  /// Guarda [config] tal cual. Nunca lanza: el almacén seguro puede fallar y
  /// se avisa al operario en vez de dejar una excepción sin manejar.
  Future<PrinterSaveResult> persist(PrinterConfig config) async {
    try {
      final active = await current();
      if (active == config) return PrinterSaveResult.unchanged;
      await _ref.read(labelPrinterProvider).selectPrinter(config);
      // La tarjeta de la impresora activa se recarga al instante.
      _ref.invalidate(selectedPrinterProvider);
      return PrinterSaveResult.saved;
    } on Object {
      return PrinterSaveResult.failed;
    }
  }

  /// Detecta el tipo de la impresora WiFi [config] y, si se identificó,
  /// guarda el perfil sugerido. Devuelve lo detectado.
  Future<PrinterDetection> detect(PrinterConfig config) async {
    PrinterDetection detection;
    try {
      detection = await _ref
          .read(printerProfileDetectorProvider)
          .detect(config.wifiHost);
    } on Object {
      detection = PrinterDetection.unknown;
    }
    final updated = detection.applyTo(config);
    if (updated != config) await persist(updated);
    return detection;
  }

  /// Olvida la impresora activa [config] (y su acceso). `false` si falló.
  Future<bool> forget(PrinterConfig config) async {
    try {
      await _ref
          .read(secureStorageProvider)
          .delete(key: LabelPrinter.selectedKey);
      await _ref.read(printerCredentialsStoreProvider).delete(config.address);
      _ref.invalidate(selectedPrinterProvider);
      return true;
    } on Object {
      return false;
    }
  }
}

/// Aviso SIEMPRE visible del resultado de guardar la impresora.
void announcePrinterSave(
  BuildContext context,
  PrinterSaveResult result,
  PrinterConfig config,
) {
  if (!context.mounted) return;
  switch (result) {
    case PrinterSaveResult.saved:
      showSuccessSnack(
        context,
        'Impresora guardada: ${config.label} (${config.address}).',
      );
    case PrinterSaveResult.unchanged:
      showInfoSnack(context, 'Esa impresora ya está guardada como activa.');
    case PrinterSaveResult.failed:
      showErrorSnack(
        context,
        'No se pudo guardar la impresora. Probá de nuevo.',
      );
  }
}
