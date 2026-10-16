import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/label_printer.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/theme/app_colors.dart';
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
              child: _ActivePrinter(
                'Activa: ${selected.label} (${selected.transport.label})',
              ),
            ),
          // En teléfonos muy angostos (o con letra grande) los íconos no entran
          // junto al texto: se muestran solo las etiquetas.
          LayoutBuilder(
            builder: (context, constraints) {
              final withIcons =
                  constraints.maxWidth /
                      MediaQuery.textScalerOf(context).scale(1) >=
                  300;
              return SegmentedButton<PrinterTransport>(
                // Sin el tilde del seleccionado (el relleno ya lo marca) y letra
                // algo menor: con el tilde "Bluetooth" se partía en dos líneas.
                showSelectedIcon: false,
                style: const ButtonStyle(
                  textStyle: WidgetStatePropertyAll(
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
                segments: [
                  ButtonSegment(
                    value: PrinterTransport.bluetooth,
                    label: const _SegmentLabel('Bluetooth'),
                    icon: withIcons ? const Icon(Icons.bluetooth) : null,
                  ),
                  ButtonSegment(
                    value: PrinterTransport.wifi,
                    label: const _SegmentLabel('WiFi'),
                    icon: withIcons ? const Icon(Icons.wifi) : null,
                  ),
                  ButtonSegment(
                    value: PrinterTransport.usb,
                    label: const _SegmentLabel('USB'),
                    icon: withIcons ? const Icon(Icons.usb) : null,
                  ),
                ],
                selected: <PrinterTransport>{_transport},
                onSelectionChanged: (value) =>
                    setState(() => _transport = value.first),
              );
            },
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

/// Impresora activa: chip verde que, a diferencia de `StatusPill`, deja
/// partir el texto en varias líneas (nombres largos de impresora en teléfonos
/// chicos no desbordan).
class _ActivePrinter extends StatelessWidget {
  const _ActivePrinter(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.success;
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.print, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de un segmento de transporte: una sola línea que se achica
/// (`scaleDown`) si no entra, en vez de partirse o cortarse con letra grande.
class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
  }
}
