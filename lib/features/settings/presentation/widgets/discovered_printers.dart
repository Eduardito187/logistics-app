import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../controllers/printer_controllers.dart';
import 'printer_option_card.dart';

/// Impresoras por Bluetooth (emparejadas) o USB (conectadas) como tarjetas
/// grandes: tocar una la elige. Debajo, "Buscar de nuevo".
class DiscoveredPrinters extends ConsumerWidget {
  const DiscoveredPrinters({
    required this.transport,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final PrinterTransport transport;
  final PrinterConfig? selected;
  final Future<void> Function(PrinterConfig config) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(discoveredPrintersProvider(transport));
    final selectedAddress = selected?.transport == transport
        ? selected?.address
        : null;
    final bluetooth = transport == PrinterTransport.bluetooth;
    final emptyMessage = bluetooth
        ? 'No hay impresoras emparejadas. Emparejá la Zebra desde los ajustes '
              'de Bluetooth del teléfono y tocá "Buscar de nuevo".'
        : 'No hay impresoras USB conectadas. Conectá la Zebra por cable, '
              'aceptá el permiso de USB y tocá "Buscar de nuevo".';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AsyncValueView<List<PrinterDevice>>(
          value: devices,
          onRetry: () => ref.invalidate(discoveredPrintersProvider(transport)),
          data: (found) {
            if (found.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(emptyMessage),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final device in found)
                  PrinterOptionCard(
                    icon: bluetooth ? AppIcon.bluetooth : AppIcon.usb,
                    title: device.name,
                    subtitle: device.address,
                    selected: device.address == selectedAddress,
                    onTap: () => onSelect(device.toConfig()),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: () =>
              ref.invalidate(discoveredPrintersProvider(transport)),
          // Gira mientras busca impresoras.
          icon: AnimatedAppIcon(
            AppIcon.refresh,
            state: devices.isLoading ? AppIconState.loading : AppIconState.idle,
            excludeFromSemantics: true,
          ),
          label: const Text('Buscar de nuevo'),
        ),
      ],
    );
  }
}
