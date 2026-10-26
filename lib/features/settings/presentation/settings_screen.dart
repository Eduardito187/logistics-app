import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/printing/label_printer.dart';
import '../../../core/printing/printer_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import 'widgets/field_use_section.dart';
import 'widgets/printer_section.dart';
import 'widgets/profile_section.dart';
import 'widgets/session_section.dart';

/// ZPL mínimo para verificar que la impresora responde.
const _testZpl = '^XA^FO40,40^A0N,40,40^FDPrueba Dismac^FS^XZ';

/// Ajustes del dispositivo: impresora Zebra, sesión y acceso a sincronización.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _printing = false;

  Future<void> _printTest() async {
    setState(() => _printing = true);
    try {
      await ref.read(labelPrinterProvider).printZpl(_testZpl);
      if (mounted) showSuccessSnack(context, 'Etiqueta de prueba enviada.');
    } on PrinterException catch (e) {
      // PrinterException trae un mensaje en español listo para el operario; se
      // muestra tal cual (app_snack.showErrorSnack sólo mapea ApiException).
      if (mounted) showInfoSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      // En tablet las secciones no se estiran de borde a borde.
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ProfileSection(),
            const SizedBox(height: 12),
            // La impresora solo le sirve a quien imprime etiquetas.
            if (session?.role.usesLabelPrinter ?? false) ...[
              PrinterSection(printing: _printing, onPrintTest: _printTest),
              const SizedBox(height: 12),
            ],
            const FieldUseSection(),
            const SizedBox(height: 12),
            SessionSection(session: session),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Cuenta y seguridad',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices),
                title: const Text('Mis dispositivos'),
                subtitle: const Text('Sesiones activas y revocar acceso.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/devices'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
