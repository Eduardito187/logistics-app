import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/printing/printer_config.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/print_test_controller.dart';
import '../controllers/printer_controllers.dart';
import '../controllers/printer_save_result.dart';
import '../controllers/printer_saver.dart';
import '../printer_setup_screen.dart';
import 'active_printer_tile.dart';
import 'print_result_text.dart';
import 'printer_actions.dart';
import 'printer_advanced_options.dart';
import 'printer_empty_state.dart';

/// Tarjeta "Impresora" de Ajustes, ESTADO PRIMERO: muestra una sola cosa
/// grande, la impresora activa (ícono, nombre, "Zebra · WiFi · IP" y estado
/// Lista / No responde) con "Imprimir prueba" y "Cambiar". Sin impresora, un
/// estado vacío con un único botón "Conectar impresora" que abre el asistente.
///
/// Todo lo técnico (tipo, protocolo, credenciales, redes extra, olvidar) vive
/// en "Opciones avanzadas", colapsado.
class PrinterSection extends ConsumerStatefulWidget {
  const PrinterSection({this.defaultUser, super.key});

  /// Usuario sugerido para impresoras de oficina que piden acceso.
  final String? defaultUser;

  @override
  ConsumerState<PrinterSection> createState() => _PrinterSectionState();
}

class _PrinterSectionState extends ConsumerState<PrinterSection> {
  bool _detecting = false;
  String? _detectionSummary;

  void _openSetup() {
    PrinterSetupScreen.open(context, defaultUser: widget.defaultUser);
  }

  /// Guarda el perfil elegido a mano en Opciones avanzadas (siempre avisa).
  Future<PrinterSaveResult> _saveProfile(PrinterConfig config) async {
    final result = await PrinterSaver(ref).persist(config);
    if (mounted) announcePrinterSave(context, result, config);
    return result;
  }

  /// "Detectar tipo de impresora" (IPP/web, nunca 9100).
  Future<void> _detect(PrinterConfig config) async {
    if (_detecting) return;
    setState(() {
      _detecting = true;
      _detectionSummary = null;
    });
    final detection = await PrinterSaver(ref).detect(config);
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _detectionSummary = detection.summary;
    });
  }

  Future<void> _forget(PrinterConfig config) async {
    final ok = await PrinterSaver(ref).forget(config);
    if (!mounted) return;
    if (ok) {
      ref.read(printTestControllerProvider.notifier).clear();
      showSuccessSnack(context, 'Impresora olvidada.');
    } else {
      showErrorSnack(
        context,
        'No se pudo olvidar la impresora. Probá de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedAsync = ref.watch(selectedPrinterProvider);
    final test = ref.watch(printTestControllerProvider);
    final selected = selectedAsync.value;

    return SectionCard(
      title: 'Impresora',
      child: switch (selected) {
        _ when !selectedAsync.hasValue && selectedAsync.isLoading =>
          const SizedBox(height: 120),
        null => PrinterEmptyState(onConnect: _openSetup),
        final PrinterConfig printer => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActivePrinterTile(printer: printer, lastResult: test.lastResult),
            const SizedBox(height: 16),
            PrinterActions(
              printing: test.printing,
              onPrintTest: () => runPrintTest(context, ref),
              onChange: _openSetup,
            ),
            if (test.lastResult case final result?) ...[
              const SizedBox(height: 12),
              PrintResultText(result),
            ],
            const Divider(height: 24),
            PrinterAdvancedOptions(
              printer: printer,
              onSaveConfig: _saveProfile,
              onForget: () => _forget(printer),
              defaultUser: widget.defaultUser,
              detecting: _detecting,
              detectionSummary: _detectionSummary,
              onDetect: () => _detect(printer),
            ),
          ],
        ),
      },
    );
  }
}
