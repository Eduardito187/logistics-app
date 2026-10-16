import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/device_list_item.dart';
import '../../../core/auth/session.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/usecases/revoke_device.dart';
import 'controllers/settings_controllers.dart';
import 'device_format.dart';
import 'settings_actions.dart';
import 'widgets/device_card.dart';

/// Pantalla "Mis dispositivos": lista las sesiones/dispositivos del usuario y
/// permite revocar una (con confirmación). El dispositivo actual se marca y su
/// revocación avisa claramente que cerrará esta sesión.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    DeviceListItem device, {
    required bool isCurrent,
  }) async {
    final name = device.name ?? platformLabel(device.platform);
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Revocar dispositivo',
      message: isCurrent
          ? 'Vas a revocar ESTE dispositivo ($name). Se cerrará tu sesión '
                'actual y tendrás que iniciar sesión de nuevo. ¿Continuar?'
          : '¿Revocar la sesión de "$name"? Ese dispositivo tendrá que '
                'iniciar sesión de nuevo.',
      confirmLabel: 'Revocar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    await runSettingsAction(
      context,
      action: () => ref.read(revokeDeviceProvider).call(device.uuid),
      success: 'Dispositivo revocado.',
      // Si se revocó ESTE dispositivo, el token actual ya quedó inválido: se
      // cierra sesión de inmediato (como promete el diálogo) en vez de esperar
      // a que el próximo 401 lo haga. Para otros dispositivos, solo se refresca
      // la lista.
      onSuccess: isCurrent
          ? () => unawaited(ref.read(sessionProvider.notifier).signOut())
          : () => ref.invalidate(devicesProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    // El dispositivo actual viene del perfil (`/app/auth/me`); si aún no cargó
    // no marcamos ninguno como actual (y no bloqueamos la revocación por error).
    final currentUuid = ref.watch(appMeProvider).value?.device?.uuid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis dispositivos')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(devicesProvider);
          ref.invalidate(appMeProvider);
          await ref.read(devicesProvider.future);
        },
        child: AsyncValueView<List<DeviceListItem>>(
          value: devices,
          onRetry: () => ref.invalidate(devicesProvider),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.devices_other,
                title: 'Sin dispositivos',
                message: 'No hay sesiones activas registradas.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final device in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DeviceCard(
                      device: device,
                      isCurrent:
                          currentUuid != null && device.uuid == currentUuid,
                      onRevoke: device.revoked
                          ? null
                          : () => _revoke(
                              context,
                              ref,
                              device,
                              isCurrent:
                                  currentUuid != null &&
                                  device.uuid == currentUuid,
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
