import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/printer_config.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../controllers/printer_controllers.dart';

/// Lista de impresoras descubiertas por Bluetooth (emparejadas) o USB
/// (conectadas). Elegir una la guarda como impresora activa.
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
    final emptyMessage = transport == PrinterTransport.bluetooth
        ? 'No hay impresoras emparejadas. Emparejá la Zebra desde los ajustes '
              'de Bluetooth del dispositivo.'
        : 'No hay impresoras USB conectadas. Conectá la Zebra por cable y '
              'aceptá el permiso de USB.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () =>
                ref.invalidate(discoveredPrintersProvider(transport)),
            icon: const Icon(Icons.refresh),
            label: const Text('Buscar'),
          ),
        ),
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
            // Flutter 3.32: sin RadioGroup, cada tile lleva groupValue/onChanged.
            return Column(
              children: [
                for (final device in found)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: device.address,
                    groupValue: selectedAddress,
                    onChanged: (_) => onSelect(device.toConfig()),
                    title: Text(device.name),
                    subtitle: Text(device.address),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
