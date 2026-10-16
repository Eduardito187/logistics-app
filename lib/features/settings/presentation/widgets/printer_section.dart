import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/label_printer.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/printer_controllers.dart';
import 'discovered_printers.dart';
import 'wifi_printer_form.dart';

/// Sección de impresora: elige transporte (Bluetooth / WiFi / USB), descubre o
/// ingresa la impresora, la guarda y permite imprimir una etiqueta de prueba.
class PrinterSection extends ConsumerStatefulWidget {
  const PrinterSection({
    required this.printing,
    required this.onPrintTest,
    super.key,
  });

  final bool printing;
  final Future<void> Function() onPrintTest;

  @override
  ConsumerState<PrinterSection> createState() => _PrinterSectionState();
}

class _PrinterSectionState extends ConsumerState<PrinterSection> {
  PrinterTransport _transport = PrinterTransport.bluetooth;

  Future<void> _save(PrinterConfig config) async {
    await ref.read(labelPrinterProvider).selectPrinter(config);
    ref.invalidate(selectedPrinterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedPrinterProvider).value;

    return SectionCard(
      title: 'Impresora de etiquetas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatusPill(
                'Activa: ${selected.label} (${selected.transport.label})',
                tone: PillTone.success,
                icon: Icons.print,
              ),
            ),
          SegmentedButton<PrinterTransport>(
            segments: const [
              ButtonSegment(
                value: PrinterTransport.bluetooth,
                label: Text('Bluetooth'),
                icon: Icon(Icons.bluetooth),
              ),
              ButtonSegment(
                value: PrinterTransport.wifi,
                label: Text('WiFi'),
                icon: Icon(Icons.wifi),
              ),
              ButtonSegment(
                value: PrinterTransport.usb,
                label: Text('USB'),
                icon: Icon(Icons.usb),
              ),
            ],
            selected: <PrinterTransport>{_transport},
            onSelectionChanged: (value) =>
                setState(() => _transport = value.first),
          ),
          const SizedBox(height: 12),
          if (_transport == PrinterTransport.wifi)
            WifiPrinterForm(initial: selected, onSave: _save)
          else
            DiscoveredPrinters(
              transport: _transport,
              selected: selected,
              onSelect: _save,
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.printing ? null : () => widget.onPrintTest(),
            icon: widget.printing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: const Text('Imprimir prueba'),
          ),
        ],
      ),
    );
  }
}
