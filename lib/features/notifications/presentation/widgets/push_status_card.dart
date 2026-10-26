import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/push/push_controller.dart';
import '../../../../core/push/push_status.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';

/// Indicador del estado de push (Firebase Cloud Messaging) con el botón para
/// activar las notificaciones.
class PushStatusCard extends ConsumerWidget {
  const PushStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final push = ref.watch(pushRegistrationProvider);
    final isBusy = push.state == PushRegistrationState.registering;

    return SectionCard(
      title: 'Notificaciones push',
      // Flexible + scaleDown: con letra grande en teléfono chico el estado
      // ("No disponible") no le quita todo el ancho al título ni desborda.
      trailing: Flexible(
        child: Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: StatusPill(push.state.label, tone: push.state.tone),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (push.isRegistered) ...[
            const SizedBox(height: 4),
            Text(
              'Recibirás avisos de la operación en este teléfono.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          if (push.message != null) ...[
            const SizedBox(height: 8),
            Text(
              push.message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          // Sin credenciales de Firebase no hay nada que activar.
          if (!push.isRegistered &&
              push.state != PushRegistrationState.unavailable) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () =>
                        ref.read(pushRegistrationProvider.notifier).register(),
              icon: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active),
              label: Text(isBusy ? 'Activando...' : 'Activar notificaciones'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Etiquetas y tonos en español para el estado de registro push. Vive junto al
/// único widget que la consume ([PushStatusCard]); no es una clase, así que no
/// rompe la regla de "una clase por archivo".
extension _PushRegistrationStateLabel on PushRegistrationState {
  String get label => switch (this) {
    PushRegistrationState.idle => 'Inactivo',
    PushRegistrationState.registering => 'Registrando',
    PushRegistrationState.registered => 'Activo',
    PushRegistrationState.unavailable => 'No disponible',
    PushRegistrationState.failed => 'Error',
  };

  PillTone get tone => switch (this) {
    PushRegistrationState.idle => PillTone.neutral,
    PushRegistrationState.registering => PillTone.info,
    PushRegistrationState.registered => PillTone.success,
    PushRegistrationState.unavailable => PillTone.warning,
    PushRegistrationState.failed => PillTone.danger,
  };
}
