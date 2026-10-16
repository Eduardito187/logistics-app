import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/device_list_item.dart';
import '../../../core/auth/session.dart';
import '../../../core/layout/responsive_body.dart';
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
    // `select`: solo reconstruye si cambia el uuid, no ante cualquier cambio
    // del perfil.
    final currentUuid = ref.watch(
      appMeProvider.select((me) => me.value?.device?.uuid),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Mis dispositivos')),
      body: ResponsiveBody(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(devicesProvider);
            ref.invalidate(appMeProvider);
            await ref.read(devicesProvider.future);
          },
          // Un solo scroll con slivers: la lista es perezosa y el estado
          // vacío/error también se refresca tirando hacia abajo.
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: switch (devices) {
              AsyncValue(:final value?, hasError: false) =>
                value.isEmpty
                    ? const [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.devices_other,
                            title: 'Sin dispositivos',
                            message: 'No hay sesiones activas registradas.',
                          ),
                        ),
                      ]
                    : [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList.separated(
                            itemCount: value.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final device = value[i];
                              final isCurrent =
                                  currentUuid != null &&
                                  device.uuid == currentUuid;
                              return DeviceCard(
                                device: device,
                                isCurrent: isCurrent,
                                onRevoke: device.revoked
                                    ? null
                                    : () => _revoke(
                                        context,
                                        ref,
                                        device,
                                        isCurrent: isCurrent,
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
              _ => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AsyncValueView<List<DeviceListItem>>(
                    value: devices,
                    onRetry: () => ref.invalidate(devicesProvider),
                    data: (_) => const SizedBox.shrink(),
                  ),
                ),
              ],
            },
          ),
        ),
      ),
    );
  }
}
