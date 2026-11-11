import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/wifi_printer_scanner.dart';
import '../../../../core/printing/wifi_scan_progress.dart';

/// Búsqueda automática de impresoras WiFi en la pantalla de ajustes.
///
/// `null` = todavía no se buscó. Al salir de la pantalla (autoDispose) se
/// cancela el barrido en curso.
class WifiPrinterDiscovery extends Notifier<WifiScanProgress?> {
  StreamSubscription<WifiScanProgress>? _sub;

  @override
  WifiScanProgress? build() {
    ref.onDispose(() => _sub?.cancel());
    return null;
  }

  /// Arranca (o reinicia) la búsqueda.
  void start() {
    unawaited(_sub?.cancel());
    state = const WifiScanProgress.starting();
    _sub = ref
        .read(wifiPrinterScannerProvider)
        .scan()
        .listen(
          (progress) => state = progress,
          onError: (Object _) => state = const WifiScanProgress.failed(
            'No se pudo buscar impresoras. Probá de nuevo o ingresá la IP.',
          ),
        );
  }

  /// Detiene la búsqueda conservando lo encontrado hasta ahora.
  void stop() {
    unawaited(_sub?.cancel());
    _sub = null;
    final current = state;
    if (current == null || current.done) return;
    state = current.stopped();
  }
}

final wifiPrinterDiscoveryProvider =
    NotifierProvider.autoDispose<WifiPrinterDiscovery, WifiScanProgress?>(
      WifiPrinterDiscovery.new,
    );
