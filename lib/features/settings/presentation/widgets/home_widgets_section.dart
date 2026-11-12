import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/home_widgets/home_widget_kind.dart';
import '../../../../core/home_widgets/home_widgets_prefs_notifier.dart';
import '../../../../core/home_widgets/home_widgets_service.dart';
import '../../../../core/home_widgets/role_home_widgets.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/section_card.dart';
import 'home_widget_tile.dart';

/// Ajustes → "Widgets de la pantalla de inicio": SOLO los widgets del rol,
/// con "Mostrar en el selector" (Android), "Agregar a la pantalla de inicio"
/// (si el launcher lo permite) y la privacidad del nombre del cliente. Las
/// preferencias son por usuario.
class HomeWidgetsSection extends ConsumerWidget {
  const HomeWidgetsSection({super.key});

  /// Aviso antes de apagar un widget en Android (deshabilitar el provider
  /// quita los widgets ya colocados).
  static const String disableWarning =
      'Si ya lo agregaste a tu pantalla de inicio, se quitará.';

  /// Cómo agregar un widget en iPhone (no hay pedido desde la app).
  static const String iosHint =
      'En iPhone, mantené presionada la pantalla de inicio → + → DisTrack.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(sessionProvider.select((s) => s?.role));
    if (role == null) return const SizedBox.shrink();
    final kinds = homeWidgetKindsFor(role);
    if (kinds.isEmpty) return const SizedBox.shrink();

    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final prefs = ref.watch(homeWidgetsPrefsProvider);
    final pinSupported =
        !isIos &&
        (ref.watch(homeWidgetsSupportProvider).value?.pinSupported ?? false);
    final notifier = ref.read(homeWidgetsPrefsProvider.notifier);
    final hideCustomer = prefs?.hideCustomer ?? false;

    return SectionCard(
      title: 'Widgets de la pantalla de inicio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final kind in kinds) ...[
            Builder(
              builder: (context) {
                final enabled =
                    kind == HomeWidgetKind.quickScan ||
                    !(prefs?.disabledKinds.contains(kind) ?? false);
                // "Escanear" va siempre en el selector: sin switch.
                final canToggle =
                    !isIos && kind != HomeWidgetKind.quickScan && prefs != null;
                return HomeWidgetTile(
                  kind: kind,
                  enabled: enabled,
                  onToggle: canToggle
                      ? (value) => _toggle(context, ref, kind, value)
                      : null,
                  onPin: pinSupported && enabled
                      ? () => _pin(context, ref, kind)
                      : null,
                );
              },
            ),
            const Divider(height: 24),
          ],
          if (isIos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AnimatedAppIcon(
                    AppIcon.add,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(iosHint, key: const Key('homeWidgetsIosHint')),
                  ),
                ],
              ),
            ),
          if (kinds.contains(HomeWidgetKind.nextDelivery))
            SwitchListTile(
              key: const Key('homeWidgetsHideCustomerSwitch'),
              contentPadding: EdgeInsets.zero,
              secondary: AnimatedAppIcon(
                AppIcon.visibilityOff,
                state: hideCustomer ? AppIconState.active : AppIconState.idle,
                excludeFromSemantics: true,
              ),
              title: const Text('Ocultar nombre del cliente en widgets'),
              subtitle: const Text('Muestra "Cliente" y no la dirección.'),
              value: hideCustomer,
              onChanged: prefs == null ? null : notifier.setHideCustomer,
            ),
        ],
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    HomeWidgetKind kind,
    bool enabled,
  ) async {
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Quitar "${kind.label}"?'),
          content: const Text(disableWarning),
          actions: [
            TextButton(
              key: const Key('homeWidgetDisableCancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('homeWidgetDisableConfirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Quitar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref
        .read(homeWidgetsPrefsProvider.notifier)
        .setKindEnabled(kind, enabled);
  }

  Future<void> _pin(
    BuildContext context,
    WidgetRef ref,
    HomeWidgetKind kind,
  ) async {
    final ok = await ref.read(homeWidgetsServiceProvider).requestPin(kind);
    if (!context.mounted) return;
    if (ok) {
      showInfoSnack(context, 'Confirmá en el aviso del teléfono.');
    } else {
      showErrorSnack(
        context,
        'No se pudo agregar. Agregalo desde la pantalla de inicio.',
      );
    }
  }
}
