import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';
import '../controllers/printer_save_result.dart';
import '../controllers/wifi_printer_discovery.dart';
import 'wifi_manual_help.dart';
import 'wifi_printer_search.dart';

/// Paso 2 del asistente por WiFi: la búsqueda arranca SOLA al entrar (el
/// operario ya eligió "WiFi": es una acción explícita) y la lista se llena en
/// vivo. Abajo, discreto, "¿No aparece? Ingresar IP" abre la ayuda manual.
///
/// Al salir del paso el provider autoDispose cancela el barrido.
class WifiPrinterStep extends ConsumerStatefulWidget {
  const WifiPrinterStep({
    required this.selected,
    required this.onSave,
    super.key,
  });

  final PrinterConfig? selected;
  final Future<PrinterSaveResult> Function(PrinterConfig config) onSave;

  @override
  ConsumerState<WifiPrinterStep> createState() => _WifiPrinterStepState();
}

class _WifiPrinterStepState extends ConsumerState<WifiPrinterStep> {
  bool _manual = false;

  @override
  void initState() {
    super.initState();
    // Después del primer frame: el build ya escucha el provider (si no,
    // autoDispose lo descartaría antes de empezar).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(wifiPrinterDiscoveryProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mantiene viva la búsqueda mientras el paso esté en pantalla.
    ref.watch(wifiPrinterDiscoveryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WifiPrinterSearch(selected: widget.selected, onSelect: widget.onSave),
        const SizedBox(height: 16),
        if (_manual)
          WifiManualHelp(selected: widget.selected, onSave: widget.onSave)
        else
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => setState(() => _manual = true),
              icon: const AnimatedAppIcon(
                AppIcon.keyboard,
                excludeFromSemantics: true,
              ),
              label: const Text('¿No aparece? Ingresar IP'),
            ),
          ),
      ],
    );
  }
}
