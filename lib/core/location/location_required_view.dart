import 'package:flutter/material.dart';

import '../icons/icons.dart';

/// Pantalla de bloqueo cuando falta la ubicación (GPS apagado o permiso de
/// primer plano no concedido).
///
/// La usa internamente [LocationPermissionGate]: explica por qué la ubicación es
/// obligatoria y ofrece abrir los Ajustes del sistema o reintentar. Pide el
/// permiso de PRIMER PLANO ("mientras se usa la app"), no "Permitir siempre".
class LocationRequiredView extends StatelessWidget {
  const LocationRequiredView({
    super.key,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedAppIcon(
            AppIcon.gpsOff,
            size: 72,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'La ubicación es obligatoria para operar el camión',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'El rastreo GPS del camión se envía automáticamente mientras estás '
            'en ruta. Necesitamos dos cosas:\n\n'
            '1) La ubicación del teléfono encendida (GPS).\n'
            '2) Permitir el acceso a la ubicación de DisTrack: con '
            '"Mientras se usa la app" alcanza.\n\n'
            'Activalos en Ajustes y volvé para continuar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 72,
            child: FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const AnimatedAppIcon(AppIcon.settings, size: 28),
              label: const Text(
                'Abrir Ajustes',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const AnimatedAppIcon(AppIcon.refresh, size: 26),
              label: const Text('Reintentar', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
