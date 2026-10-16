import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/label_printer.dart';
import '../../../../core/printing/printer_config.dart';

/// Controllers de impresión del feature de ajustes. Leen del core de impresión
/// (`labelPrinterProvider`), no del cliente de la API.

/// Impresoras descubiertas para el [PrinterTransport] elegido en la UI.
/// Bluetooth = emparejadas, USB = conectadas, WiFi = lista vacía (manual).
final discoveredPrintersProvider = FutureProvider.autoDispose
    .family<List<PrinterDevice>, PrinterTransport>((ref, transport) {
      return ref.read(labelPrinterProvider).discover(transport);
    });

/// Impresora seleccionada y persistida en almacenamiento seguro.
final selectedPrinterProvider = FutureProvider.autoDispose<PrinterConfig?>((
  ref,
) {
  return ref.read(labelPrinterProvider).selectedPrinter();
});
