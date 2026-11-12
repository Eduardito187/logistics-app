import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive_body.dart';
import '../../../core/printing/printer_config.dart';
import '../../../core/printing/printer_detection.dart';
import 'controllers/print_test_controller.dart';
import 'controllers/printer_controllers.dart';
import 'controllers/printer_save_result.dart';
import 'controllers/printer_saver.dart';
import 'printer_setup_step.dart';
import 'widgets/discovered_printers.dart';
import 'widgets/printer_done_step.dart';
import 'widgets/printer_transport_step.dart';
import 'widgets/wifi_printer_step.dart';

/// Asistente "Conectar impresora" a pantalla completa, en pasos de UNA
/// decisión: 1) ¿Cómo se conecta? 2) Elegí tu impresora 3) Listo.
///
/// Guardar SIEMPRE avisa el resultado; una WiFi nueva se guarda y después se
/// detecta su tipo (IPP/web, nunca 9100). Atrás vuelve un paso.
class PrinterSetupScreen extends ConsumerStatefulWidget {
  const PrinterSetupScreen({this.defaultUser, super.key});

  /// Usuario sugerido para impresoras de oficina que piden acceso.
  final String? defaultUser;

  /// Abre el asistente sobre toda la app (sin la barra inferior).
  static Future<void> open(BuildContext context, {String? defaultUser}) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => PrinterSetupScreen(defaultUser: defaultUser),
      ),
    );
  }

  @override
  ConsumerState<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends ConsumerState<PrinterSetupScreen> {
  PrinterSetupStep _step = PrinterSetupStep.transport;
  PrinterTransport _transport = PrinterTransport.bluetooth;
  PrinterConfig? _chosen;
  bool _detecting = false;
  PrinterDetection? _detection;

  /// Sube con cada elección: descarta detecciones viejas.
  int _generation = 0;

  void _pickTransport(PrinterTransport transport) {
    setState(() {
      _transport = transport;
      _step = PrinterSetupStep.choose;
    });
  }

  /// Guarda la impresora elegida, avisa y pasa a "Listo" (si se guardó).
  Future<PrinterSaveResult> _choose(PrinterConfig config) async {
    final saver = PrinterSaver(ref);
    final outcome = await saver.choose(config);
    if (!mounted) return outcome.result;
    announcePrinterSave(context, outcome.result, outcome.config);
    if (outcome.result == PrinterSaveResult.failed) return outcome.result;
    ref.read(printTestControllerProvider.notifier).clear();
    final generation = ++_generation;
    setState(() {
      _chosen = outcome.config;
      _detection = null;
      _detecting = outcome.isNewWifi;
      _step = PrinterSetupStep.done;
    });
    if (outcome.isNewWifi) {
      final detection = await saver.detect(outcome.config);
      if (!mounted || generation != _generation) return outcome.result;
      setState(() {
        _detecting = false;
        _detection = detection;
        _chosen = detection.applyTo(outcome.config);
      });
    }
    return outcome.result;
  }

  void _back() {
    switch (_step) {
      case PrinterSetupStep.transport || PrinterSetupStep.done:
        Navigator.of(context).maybePop();
      case PrinterSetupStep.choose:
        setState(() => _step = PrinterSetupStep.transport);
    }
  }

  String _chooseHint() => switch (_transport) {
    PrinterTransport.bluetooth =>
      'Impresoras emparejadas con este teléfono. Tocá la tuya.',
    PrinterTransport.wifi =>
      'Buscando impresoras en tu WiFi. Tocá la tuya cuando aparezca.',
    PrinterTransport.usb => 'Impresoras conectadas por cable. Tocá la tuya.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedPrinterProvider).value;
    final step = _step;
    final chosen = _chosen;

    return PopScope(
      // En "Elegí" atrás vuelve al paso 1 en vez de cerrar el asistente.
      canPop: step != PrinterSetupStep.choose,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conectar impresora'),
          leading: BackButton(onPressed: _back),
        ),
        body: SafeArea(
          child: ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Paso ${step.number} de ${PrinterSetupStep.count}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: step.number / PrinterSetupStep.count,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 16),
                if (step != PrinterSetupStep.done) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      step.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step == PrinterSetupStep.transport
                        ? 'Elegí una opción.'
                        : _chooseHint(),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                ],
                switch (step) {
                  PrinterSetupStep.transport => PrinterTransportStep(
                    onPick: _pickTransport,
                  ),
                  PrinterSetupStep.choose =>
                    _transport == PrinterTransport.wifi
                        ? WifiPrinterStep(selected: selected, onSave: _choose)
                        : DiscoveredPrinters(
                            transport: _transport,
                            selected: selected,
                            onSelect: _choose,
                          ),
                  PrinterSetupStep.done =>
                    chosen == null
                        ? const SizedBox.shrink()
                        : PrinterDoneStep(
                            printer: chosen,
                            detecting: _detecting,
                            detection: _detection,
                            defaultUser: widget.defaultUser,
                            onFinish: () => Navigator.of(context).maybePop(),
                          ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}
