import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/label_printer.dart';
import '../../../../core/printing/printer_config.dart';
import '../../../../core/widgets/app_snack.dart';
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
    // El guardado (almacén seguro) puede fallar: se avisa al operario en vez de
    // dejar una excepción async sin manejar (pantalla roja en debug / silencio).
    try {
      await ref.read(labelPrinterProvider).selectPrinter(config);
      ref.invalidate(selectedPrinterProvider);
    } on Object {
      if (mounted) {
        showInfoSnack(
          context,
          'No se pudo guardar la impresora. Probá de nuevo.',
        );
      }
    }
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
              child: Align(
                alignment: Alignment.centerLeft,
                // scaleDown: con letra grande en teléfono chico la pastilla se
                // achica en vez de desbordar (mismo patrón que device_card).
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatusPill(
                    'Activa: ${selected.label} (${selected.transport.label})',
                    tone: PillTone.success,
                    icon: Icons.print,
                  ),
                ),
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
