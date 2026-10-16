import 'package:flutter/material.dart';

/// Pantalla de bloqueo cuando falta el permiso de ubicación "siempre".
///
/// La usa internamente [LocationPermissionGate] cuando el permiso de segundo
/// plano no está concedido: explica por qué la ubicación es obligatoria y ofrece
/// abrir los Ajustes del sistema o reintentar.
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
          Icon(Icons.location_off, size: 72, color: theme.colorScheme.error),
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
            'El rastreo GPS del camión se envía de forma automática mientras '
            'estás en ruta, también con la app en segundo plano. Para eso '
            'necesitamos el permiso de ubicación en modo "Permitir siempre".\n\n'
            'Activá "Permitir siempre" en Ajustes y volvé para continuar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 72,
            child: FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings, size: 28),
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
              icon: const Icon(Icons.refresh, size: 26),
              label: const Text('Reintentar', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
