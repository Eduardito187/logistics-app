import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/app_me_response.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/settings_controllers.dart';
import 'biometric_login_tile.dart';

/// Sección de perfil: nombre, correo, roles y dispositivo actual del usuario,
/// con acción para refrescar (`/app/auth/me`) y el switch de ingreso con
/// biometría ([BiometricLoginTile]).
class ProfileSection extends ConsumerWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appMeProvider);
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Perfil',
      trailing: IconButton(
        // Gira mientras recarga el perfil.
        icon: AnimatedAppIcon(
          AppIcon.refresh,
          state: profile.isLoading ? AppIconState.loading : AppIconState.idle,
          excludeFromSemantics: true,
        ),
        tooltip: 'Actualizar',
        onPressed: () => ref.invalidate(appMeProvider),
      ),
      child: AsyncValueView<AppMeResponse>(
        value: profile,
        onRetry: () => ref.invalidate(appMeProvider),
        data: (me) {
          final device = me.device;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AnimatedAppIcon(AppIcon.profile),
                title: Text(me.user.name),
                subtitle: Text(me.user.email),
              ),
              if (me.user.roles.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // scaleDown: un rol largo se achica en vez de desbordar
                    // (`StatusPill` no parte su texto).
                    for (final role in me.user.roles)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatusPill(role, tone: PillTone.info),
                      ),
                  ],
                ),
              ],
              if (device != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    AnimatedAppIcon(
                      AppIcon.phone,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dispositivo: ${device.name ?? device.platform ?? device.uuid}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Ingreso con huella / rostro (solo si el teléfono lo tiene).
              const SizedBox(height: 4),
              BiometricLoginTile(email: me.user.email, name: me.user.name),
            ],
          );
        },
      ),
    );
  }
}
