import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/map/map_launcher.dart';
import '../../controllers/driver_controllers.dart';
import '../../failed_delivery_screen.dart';
import '../../report_issue_screen.dart';
import 'delivery_actions_bar.dart';
import 'delivery_contact.dart';

/// "Ayuda" de la entrega en curso: sin chat. Reúne llamar al cliente, navegar
/// con la app de mapas y reportar al backend lo que impide o complica la
/// entrega (no se pudo entregar con su motivo, problema del vehículo).
///
/// Las acciones que abren otra pantalla usan el `context`/`ref` de la pantalla
/// que llama ([ref]): los de la hoja dejan de estar montados al cerrarla.
Future<void> showDeliveryHelpSheet(
  BuildContext context,
  WidgetRef ref, {
  required DriverRouteStop stop,
}) {
  final router = GoRouter.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => DeliveryHelpSheet(
      stop: stop,
      onScanUnits: () => unawaited(
        openDeliveryStep(context, ref, stop, unloadScreenFor(stop)),
      ),
      onFailedDelivery: () => unawaited(
        openDeliveryStep(context, ref, stop, FailedDeliveryScreen(stop: stop)),
      ),
      onReportIssue: () => unawaited(
        openDeliveryStep(context, ref, stop, ReportIssueScreen(stop: stop)),
      ),
      onOpenRoute: (path) {
        if (router != null) unawaited(router.push(path));
      },
    ),
  );
}

class DeliveryHelpSheet extends ConsumerWidget {
  const DeliveryHelpSheet({
    super.key,
    required this.stop,
    required this.onScanUnits,
    required this.onFailedDelivery,
    required this.onReportIssue,
    required this.onOpenRoute,
  });

  final DriverRouteStop stop;
  final VoidCallback onScanUnits;
  final VoidCallback onFailedDelivery;
  final VoidCallback onReportIssue;
  final void Function(String path) onOpenRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final phone =
        stop.customerPhone ??
        ref.watch(shipmentDetailProvider(stop.shipmentId)).value?.customerPhone;
    final hasLocation = stop.lat != null && stop.lng != null;
    final navigator = Navigator.of(context);

    void closeThen(void Function() action) {
      navigator.pop();
      action();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Ayuda con esta entrega',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (phone != null && phone.isNotEmpty)
              _HelpTile(
                icon: Icons.call,
                title: 'Llamar al cliente',
                subtitle: phone,
                onTap: () => closeThen(() => unawaited(dialPhone(phone))),
              ),
            if (hasLocation)
              _HelpTile(
                icon: Icons.navigation,
                title: 'Abrir en la app de mapas',
                subtitle: 'Indicaciones paso a paso hasta el cliente',
                onTap: () => closeThen(
                  () => unawaited(
                    openExternalNavigation(
                      stop.lat!,
                      stop.lng!,
                      label: stop.customerName,
                    ),
                  ),
                ),
              ),
            _HelpTile(
              icon: Icons.qr_code_scanner,
              title: 'Escanear bultos',
              subtitle: 'QR o código de barras de las etiquetas',
              onTap: () => closeThen(onScanUnits),
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Reportar un inconveniente',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _HelpTile(
              icon: Icons.report_outlined,
              title: 'Otro inconveniente',
              subtitle:
                  'Demora, acceso restringido, el cliente pide esperar… '
                  '(la entrega sigue)',
              onTap: () => closeThen(onReportIssue),
            ),
            _HelpTile(
              icon: Icons.person_off_outlined,
              title: 'No se pudo entregar',
              subtitle:
                  'Cliente ausente, dirección incorrecta, rechazo o producto '
                  'dañado',
              danger: true,
              onTap: () => closeThen(onFailedDelivery),
            ),
            _HelpTile(
              icon: Icons.car_crash_outlined,
              title: 'Problema con el vehículo',
              subtitle: 'Avería o accidente',
              danger: true,
              onTap: () => closeThen(() => onOpenRoute('/driver/incident')),
            ),
            _HelpTile(
              icon: Icons.map_outlined,
              title: 'Ver la ruta completa',
              subtitle: 'Todas las paradas del día',
              onTap: () => closeThen(() => onOpenRoute('/driver/route')),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
