import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/nav_clearance.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/section_card.dart';
import '../../driver/presentation/widgets/route_island_settings_tile.dart';
import 'widgets/home_widgets_section.dart';
import 'controllers/settings_controllers.dart';
import 'widgets/field_use_section.dart';
import 'widgets/printer_section.dart';
import 'widgets/profile_section.dart';
import 'widgets/session_section.dart';

/// Ajustes del dispositivo: impresora (estado + asistente), sesión y cuenta.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Usuario sugerido para la impresora: parte local del email de la sesión.
  String? _defaultPrinterUser() {
    final email = ref.watch(appMeProvider).value?.user.email.trim() ?? '';
    final at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return email.isEmpty ? null : email;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      // En tablet las secciones no se estiran de borde a borde.
      body: ResponsiveBody(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            navScrollBottomPadding(context),
          ),
          children: [
            const ProfileSection(),
            const SizedBox(height: 12),
            // La impresora solo le sirve a quien imprime etiquetas.
            if (session?.role.usesLabelPrinter ?? false) ...[
              PrinterSection(defaultUser: _defaultPrinterUser()),
              const SizedBox(height: 12),
            ],
            const FieldUseSection(),
            const SizedBox(height: 12),
            // Isla de ruta (chofer): se oculta sola para otros roles.
            const RouteIslandSettingsTile(),
            // Widgets de la pantalla de inicio (vacío sin sesión o sin widgets
            // para el rol).
            const HomeWidgetsSection(),
            const SizedBox(height: 12),
            SessionSection(session: session),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Cuenta y seguridad',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    // 2FA = candado de seguridad (brief §4.3 `security`).
                    leading: const AnimatedAppIcon(AppIcon.security),
                    title: const Text('Verificación en dos pasos'),
                    subtitle: const Text(
                      'Un código extra de tu teléfono al ingresar.',
                    ),
                    trailing: const AnimatedAppIcon(AppIcon.chevronRight),
                    onTap: () => context.push('/settings/security'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const AnimatedAppIcon(AppIcon.devices),
                    title: const Text('Mis dispositivos'),
                    subtitle: const Text('Sesiones activas y revocar acceso.'),
                    trailing: const AnimatedAppIcon(AppIcon.chevronRight),
                    onTap: () => context.push('/settings/devices'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
