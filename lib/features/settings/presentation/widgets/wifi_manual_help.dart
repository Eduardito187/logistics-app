import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/ipv4_subnet.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/printing/wifi_printer_scanner.dart';
import '../controllers/printer_save_result.dart';
import 'wifi_extra_networks.dart';
import 'wifi_printer_form.dart';

/// Ayuda de "¿No aparece?": IP a mano con "Probar conexión" y, más abajo y
/// colapsado, "Buscar en otra red" (redes extra que barre la búsqueda).
class WifiManualHelp extends ConsumerStatefulWidget {
  const WifiManualHelp({
    required this.selected,
    required this.onSave,
    super.key,
  });

  final PrinterConfig? selected;
  final Future<PrinterSaveResult> Function(PrinterConfig config) onSave;

  @override
  ConsumerState<WifiManualHelp> createState() => _WifiManualHelpState();
}

class _WifiManualHelpState extends ConsumerState<WifiManualHelp> {
  bool _otherNetwork = false;

  /// Redes reales del teléfono (para avisar si la IP es de otra red).
  Future<List<Ipv4Subnet>> _phoneNetworks() async {
    final scanner = ref.read(wifiPrinterScannerProvider);
    return [for (final n in await scanner.localNetworks()) n.subnet];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ingresá la IP de la impresora',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Está en la pantalla o en la hoja de configuración de la impresora.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        WifiPrinterForm(
          initial: widget.selected,
          onSave: widget.onSave,
          onTest: (host, port) =>
              ref.read(wifiPrinterScannerProvider).diagnose(host, port: port),
          phoneNetworks: _phoneNetworks,
        ),
        const SizedBox(height: 8),
        if (_otherNetwork) ...[
          const WifiExtraNetworks(),
          const SizedBox(height: 4),
          Text(
            'Después tocá "Buscar de nuevo" arriba.',
            style: theme.textTheme.bodySmall,
          ),
        ] else
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => setState(() => _otherNetwork = true),
            icon: const AnimatedAppIcon(
              AppIcon.lan,
              excludeFromSemantics: true,
            ),
            label: const Text('Buscar en otra red'),
          ),
      ],
    );
  }
}
