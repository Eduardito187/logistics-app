import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/printing/printer_config.dart';
import '../controllers/printer_save_result.dart';
import 'printer_access_section.dart';
import 'wifi_extra_networks.dart';

/// "Opciones avanzadas" de la impresora activa, COLAPSADAS por defecto (el
/// operario normal nunca las ve). Adentro, para WiFi: tipo Zebra/Oficina,
/// cómo se envía (IPP / 9100, explicado), usuario/dominio/contraseña/código
/// y redes adicionales. Para todas: "Olvidar impresora".
class PrinterAdvancedOptions extends StatefulWidget {
  const PrinterAdvancedOptions({
    required this.printer,
    required this.onSaveConfig,
    required this.onForget,
    this.defaultUser,
    this.detecting = false,
    this.detectionSummary,
    this.onDetect,
    super.key,
  });

  final PrinterConfig printer;
  final Future<PrinterSaveResult> Function(PrinterConfig config) onSaveConfig;

  /// Olvida la impresora (ya confirmado por el operario).
  final Future<void> Function() onForget;

  final String? defaultUser;
  final bool detecting;
  final String? detectionSummary;
  final VoidCallback? onDetect;

  @override
  State<PrinterAdvancedOptions> createState() => _PrinterAdvancedOptionsState();
}

class _PrinterAdvancedOptionsState extends State<PrinterAdvancedOptions> {
  bool _open = false;

  Future<void> _confirmForget() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const AnimatedAppIcon(
          AppIcon.delete,
          state: AppIconState.active,
          size: 40,
        ),
        title: const Text('¿Olvidar impresora?'),
        content: Text(
          'Se borra ${widget.printer.label} de este teléfono. Para imprimir '
          'vas a tener que conectarla de nuevo.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Olvidar'),
          ),
        ],
      ),
    );
    if (ok ?? false) await widget.onForget();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wifi = widget.printer.transport == PrinterTransport.wifi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  AnimatedAppIcon(
                    AppIcon.settings,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Opciones avanzadas',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedAppIcon(
                      AppIcon.expandMore,
                      color: theme.colorScheme.onSurfaceVariant,
                      excludeFromSemantics: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          if (wifi) ...[
            PrinterAccessSection(
              printer: widget.printer,
              onSaveConfig: widget.onSaveConfig,
              defaultUser: widget.defaultUser,
              detecting: widget.detecting,
              detectionSummary: widget.detectionSummary,
              onDetect: widget.onDetect,
            ),
            const Divider(height: 32),
            const WifiExtraNetworks(),
            const Divider(height: 32),
          ],
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 56),
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: _confirmForget,
            icon: AnimatedAppIcon(
              AppIcon.delete,
              color: theme.colorScheme.error,
              excludeFromSemantics: true,
            ),
            label: const Text('Olvidar impresora'),
          ),
        ],
      ],
    );
  }
}
